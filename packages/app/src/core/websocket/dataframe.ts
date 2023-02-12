type ConnectionReader = (length: number) => Promise<string>;

function decodeBigEndian(data: string): number {
    let number = 0;
    for (let i = 0; i <= data.length; i++)
        number = (number << 8) | string.byte(data, i);
    return number;
}

function encodeBigEndian(value: number, length: number): string {
    const bytes = [];
    for (let i = length-1; i >= 0; i--) {
        bytes[i] = value & 0xFF;
        value >>= 8;
    }
    return string.char(...bytes);
}

function parseHeader(data: string) {
    const [firstByte, secondByte] = string.byte(data, 1, 2);

    const fin = (firstByte & 0b1000_0000) !== 0;
    const rsv1 = (firstByte & 0b0100_0000) !== 0;
    const rsv2 = (firstByte & 0b0010_0000) !== 0;
    const rsv3 = (firstByte & 0b0001_0000) !== 0;
    const opcode = firstByte & 0xF;

    const mask = (secondByte & 0b1000_0000) !== 0;
    const payloadLength = secondByte & 0b0111_1111;

    return { fin, rsv1, rsv2, rsv3, opcode, mask, payloadLength };
}

function parseExtendedHeader(data: string) {
    let hasMask = (data.length === 4 || data.length === 6 || data.length === 12);
    const rawPayloadLength = data.substring(0, data.length - (hasMask ? 4 : 0));
    const rawMaskingKey = data.substring(rawPayloadLength.length);

    const payloadLength = decodeBigEndian(rawPayloadLength);
    const maskingKey = string.byte(rawMaskingKey, 1, 4);

    return { payloadLength, maskingKey };
}

function applyXORMask(data: string, mask: readonly number[]) {
    return data.split('')
        .map((char, index) => string.char(string.byte(char) ^ mask[index % 4]))
        .join('');
}

export enum OpCode {
    /* -- Data Frames -- */
    Continuation = 0x0,
    Text = 0x1,
    Binary = 0x2,

    /* -- Control Frames -- */
    Close = 0x8,
    Ping = 0x9,
    Pong = 0xA,
}

export enum CloseCode {
    /**
     * 1000 indicates a normal closure, meaning that the purpose for
     * which the connection was established has been fulfilled.
     */
    Normal = 1000,
    /**
     * 1001 indicates that an endpoint is "going away", such as a server
     * going down or a browser having navigated away from a page.
     */
    GoingAway = 1001,
    /**
     * 1002 indicates that an endpoint is terminating the connection due
     * to a protocol error.
     */
    ProtocolError = 1002,
    /**
     * 1003 indicates that an endpoint is terminating the connection
     * because it has received a type of data it cannot accept (e.g., an
     * endpoint that understands only text data MAY send this if it
     * receives a binary message).
     */
    UnsupportedFrame = 1003,

    // TODO: Add the rest of code from section 7.4.1 of RFC6455.
}

export class DataFrame {
    constructor(
        public readonly fin: boolean,
        public readonly rsv1: boolean,
        public readonly rsv2: boolean,
        public readonly rsv3: boolean,
        public readonly opcode: OpCode,
        public readonly maskingKey: readonly number[] | undefined,
        public readonly payload: string,
    ) {
        // 450_359_9627_370_500 = 2^52
        if (payload.length >= 450_359_9627_370_500) throw 'payload too large.';
    }

    get isControl() { return (this.opcode & 0x8) !== 0 }

    get isText() { return this.opcode === OpCode.Text }
    get isBinary() { return this.opcode === OpCode.Binary }
    get isClose() { return this.opcode === OpCode.Close }
    get isPing() { return this.opcode === OpCode.Ping }
    get isPong() { return this.opcode === OpCode.Pong }

    get closeCode() {
        if (this.opcode !== OpCode.Close) return -1;
        if (this.payload === '') return CloseCode.Normal;
        return decodeBigEndian(this.payload.substring(0, 2));
    }

    encode(): string {
        const header = this.encodeHeader();
        const extendedHeader = this.encodeExtendedHeader();
        const payload = (this.maskingKey !== undefined) ? applyXORMask(this.payload, this.maskingKey) : this.payload;

        return `${header}${extendedHeader}${payload}`;
    }

    private encodeHeader(): string {
        let firstByte = 0, secondByte = 0;

        if (this.fin) firstByte |= 0b1000_0000;
        if (this.rsv1) firstByte |= 0b0100_0000;
        if (this.rsv2) firstByte |= 0b0010_0000;
        if (this.rsv3) firstByte |= 0b0001_0000;
        firstByte |= this.opcode;

        if (this.maskingKey !== undefined) secondByte |= 0b1000_0000;

        if (this.payload.length > 0xFFFF) secondByte |= 127;
        else secondByte |= Math.min(this.payload.length, 126);

        return string.char(firstByte, secondByte);
    }

    private encodeExtendedHeader(): string {
        const mask = (this.maskingKey !== undefined) ? string.char(...this.maskingKey) : '';
        const payloadLength = (this.payload.length >= 126) ? encodeBigEndian(this.payload.length,
            this.payload.length > 0xFFFF ? 8 : 2
        ) : '';

        return `${payloadLength}${mask}`;
    }

    static async parse(reader: ConnectionReader): Promise<DataFrame> {
        const header = await reader(2);

        const {
            fin, rsv1, rsv2, rsv3, opcode,
            mask, payloadLength: basePayloadLength
        } = parseHeader(header);

        let extendedHeaderLength = mask ? 4 : 0;
        if (basePayloadLength === 126) extendedHeaderLength += 2;
        if (basePayloadLength === 127) extendedHeaderLength += 8;

        const extendedHeader = await reader(extendedHeaderLength);
        const { payloadLength: extendedPayloadLength, maskingKey } = parseExtendedHeader(extendedHeader);

        const payloadLength = (basePayloadLength < 126) ? basePayloadLength : extendedPayloadLength;

        const rawPayload = await reader(payloadLength);
        const payload = mask ? applyXORMask(rawPayload, maskingKey) : rawPayload;

        return new DataFrame(fin, rsv1, rsv2, rsv3, opcode, maskingKey, payload);
    }

    static createTextFrame(data: string): DataFrame {
        return new DataFrame(
            true, false, false, false,
            OpCode.Text, undefined, data,
        );
    }

    /**
     * @param binary Whether to send as binary data or UTF-8 text.
     * @param fragmentLength (Maximum length: 450_359_9627_370_500 = 2^52).
     */
    static createDataFrames(data: string, binary: boolean, fragmentLength = 450_359_9627_370_500): DataFrame[] {
        const frames: DataFrame[] = [];

        const dataLength = data.length;
        const framesCount = Math.ceil(dataLength / fragmentLength);
        const lastFrameId = Math.max(framesCount - 1, 0);

        for (let frameId = 0; frameId < framesCount; frameId++)
            frames.push(new DataFrame(
                frameId === lastFrameId, false, false, false,
                frameId === 0 ? (binary ? OpCode.Binary : OpCode.Text) : OpCode.Continuation,
                undefined,
                data.substring(frameId * fragmentLength, (frameId + 1) * fragmentLength),
            ));

        return frames;
    }

    static createCloseFrame(code: CloseCode = CloseCode.Normal, reason?: string): DataFrame {
        return new DataFrame(
            true, false, false, false,
            OpCode.Close, undefined,
            `${encodeBigEndian(code, 2)}${reason ?? ''}`,
        );
    }

    static createPingFrame(data?: string) {
        return new DataFrame(
            true, false, false, false,
            OpCode.Ping, undefined,
            data ?? '',
        );
    }

    static createPongFrame(data?: string) {
        return new DataFrame(
            true, false, false, false,
            OpCode.Pong, undefined,
            data ?? '',
        );
    }
}