import { WebSocketConnection } from './connection';

function decodeLittleEndian(data: string): number {
    data = string.reverse(data);

    let number = 0;
    for (let i = 0; i <= data.length; i++)
        number = (number << 8) | string.byte(data, i);
    return number;
}

function parseHeader(data: string) {
    const [firstByte, secondByte] = string.byte(data, 1, 2);

    const fin = (firstByte & 0b1000_000) !== 0;
    const rsv1 = (firstByte & 0b0100_000) !== 0;
    const rsv2 = (firstByte & 0b0010_000) !== 0;
    const rsv3 = (firstByte & 0b0001_000) !== 0;
    const opcode = firstByte & 0xF;

    const mask = (secondByte & 0b1000_0000) !== 0;
    const payloadLength = secondByte & 0b0111_1111;

    return { fin, rsv1, rsv2, rsv3, opcode, mask, payloadLength };
}

function parseExtendedHeader(data: string) {
    let hasMask = (data.length === 4 || data.length === 6 || data.length === 10);
    const rawPayloadLength = data.substring(0, data.length - (hasMask ? 4 : 0));
    const rawMaskingKey = data.substring(rawPayloadLength.length);

    const payloadLength = decodeLittleEndian(rawPayloadLength);
    const maskingKey = string.byte(rawMaskingKey, 1, 4);

    return { payloadLength, maskingKey };
}

function applyXORMask(data: string, mask: number[]) {
    return data.split('')
        .map((char, index) => string.char(string.byte(char) ^ mask[index % 4]))
        .join('');
}

export class DataFrame {
    constructor (
        public readonly fin: boolean,
        public readonly rsv1: boolean,
        public readonly rsv2: boolean,
        public readonly rsv3: boolean,
        public readonly opcode: number,
        public readonly maskingKey: readonly number[] | undefined,
        public readonly payload: string,
    ) {}

    static receiveFrame(connection: WebSocketConnection): DataFrame {
        const header = connection.readBytes(2);

        const {
            fin, rsv1, rsv2, rsv3, opcode,
            mask, payloadLength: basePayloadLength
        } = parseHeader(header);

        let extendedHeaderLength = mask ? 4 : 0;
        if (basePayloadLength === 126) extendedHeaderLength += 2;
        if (basePayloadLength === 127) extendedHeaderLength += 8;

        const extendedHeader = connection.readBytes(extendedHeaderLength);
        const { payloadLength: extendedPayloadLength, maskingKey } = parseExtendedHeader(extendedHeader);

        const payloadLength = (basePayloadLength < 126) ? basePayloadLength : extendedPayloadLength;

        const rawPayload = connection.readBytes(payloadLength);
        const payload = mask ? applyXORMask(rawPayload, maskingKey) : rawPayload;

        return new DataFrame(fin, rsv1, rsv2, rsv3, opcode, maskingKey, payload);
    }
}