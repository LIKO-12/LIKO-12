import { addJob } from './async-jobs-worker';
import { reasonPhrases } from './reason-phrases';

type HTTPMethod = 'OPTIONS' | 'GET' | 'HEAD' | 'POST' | 'PUT' | 'DELETE' | 'TRACE' | 'CONNECT';

interface RequestLine {
    method: HTTPMethod,
    uri: string,
    major: number,
    minor: number,
}

class HTTPError extends Error {
    constructor(msg: string, public readonly code: number = 400) {
        super(msg);
    }
}

export class WebSocketHandshake {
    /**
     * The handshake request headers received.
     * 
     * **Note:** the keys are in lower-snake-case.
     */
    private readonly _requestHeaders: Record<string, string | undefined> = {};
    get requestHeaders(): Readonly<Record<string, string | undefined>> { return this._requestHeaders; }

    private _requestLine?: RequestLine;
    get requestLine(): Readonly<RequestLine> { return this._requestLine!; }

    private constructor(
        private readonly client: TCPSocket,
    ) { }

    static async perform(client: TCPSocket): Promise<WebSocketHandshake> {
        const handshake = new WebSocketHandshake(client);

        try {
            await handshake._readRequestLine();
            handshake._verifyRequestLine();

            await handshake._readHeaders();
            handshake._verifyHeaders();
        } catch (err: unknown) {
            const httpError = (err instanceof HTTPError) ? err : new HTTPError(`${err}`, 500);
            await handshake._sendErrorResponse(httpError);
            throw err;
        }

        await handshake._sendSuccessResponse();

        return handshake;
    }

    //#region Request Processing

    private _readLine(): Promise<string> {
        return new Promise((resolve, reject) => {
            addJob(() => {
                const [line, err] = this.client.receive('*l');
                if (err === 'timeout') return false;

                if (line === undefined) reject(err);
                else resolve(line);

                return true;
            });
        });
    }

    private async _readRequestLine(): Promise<void> {
        // RFC2616 5.1 Request-Line
        const requestLine = await this._readLine();
        const [method, uri, majorRaw, minorRaw] = string.match(requestLine, '^(%a+) (%S+) HTTP/(%d+)%.(%d+)$');

        const major = tonumber(majorRaw), minor = tonumber(minorRaw);
        if (method === undefined || major === undefined || minor === undefined)
            throw new HTTPError('invalid request line');

        this._requestLine = { method: method as HTTPMethod, uri, major, minor };
    }

    private _verifyRequestLine(): void {
        if (this._requestLine?.method !== 'GET')
            throw new HTTPError('unsupported HTTP method');
        if (this._requestLine?.major !== 1 || this._requestLine?.minor < 1)
            throw new HTTPError('unsupported HTTP version');
    }

    private async _readHeaders(): Promise<void> {
        // RFC6455 4.2 Server-Side Requirements
        while (true) {
            const line = await this._readLine();
            if (line === '') break;

            const [key, value] = string.match(line, '^([^:]+):%s+(.+)$');
            if (key === undefined || value === undefined)
                throw new HTTPError('invalid header line');

            this._requestHeaders[key.toLowerCase()] = value;
        }
    }

    private _verifyHeaders(): void {
        if (this._requestHeaders['host'] !== 'localhost:50000') throw new HTTPError('non-whitelisted host', 403); // http 403 forbidden
        if (this._requestHeaders['origin'] !== 'http://localhost:8080') throw new HTTPError('non-whitelisted origin', 403); // http 403 forbidden

        if (this._requestHeaders['upgrade']?.toLowerCase() !== 'websocket') throw new HTTPError("invalid/missing 'Upgrade' header");
        if (this._requestHeaders['connection']?.toLowerCase() !== 'upgrade') throw new HTTPError("invalid/missing 'Connection' header");

        if (this._requestHeaders['sec-websocket-version'] !== '13') throw new HTTPError('unsupported websocket version');
        // TODO: send http 426 upgrade required with the right version.

        const wsKeyEncoded = this._requestHeaders['sec-websocket-key'];
        if (wsKeyEncoded === undefined) throw new HTTPError("missing 'Sec-WebSocket-Key' header");

        const wsKey = love.data.decode('string', 'base64', wsKeyEncoded);
        if (wsKey.length !== 16) throw new HTTPError("invalid 'Sec-WebSocket-Key' header");
    }

    //#endregion

    //#region Response Processing

    private _sendLine(line: string): Promise<void> {
        let lastByteSent = 0;
        return new Promise((resolve, reject) => {
            const [bytesSent, err, fragmentSent] = this.client.send(`${line}\r\n`, lastByteSent + 1);
            if (err === 'timeout') {
                lastByteSent = fragmentSent;
                return false;
            }

            if (bytesSent === undefined) reject(err);
            else if (bytesSent !== line.length + 2) reject('bytes count did not matched!');
            else resolve();

            return true;
        });
    }

    private _sendStatusLine(code: number): Promise<void> {
        const reasonPhrase = reasonPhrases[code];
        if (reasonPhrase === undefined) throw `unknown status code (${code})!`;

        return this._sendLine(`HTTP/1.1 ${code} ${reasonPhrase}`);
    }

    private async _sendHeaders(headers: Record<string, string>): Promise<void> {
        for (const [key, value] of pairs(headers))
            await this._sendLine(`${key}: ${value}`);
        await this._sendLine('');
    }

    private async _sendErrorResponse(err: HTTPError): Promise<void> {
        const message = `Error: ${err.message}`;

        await this._sendStatusLine(err.code);
        await this._sendHeaders({
            ['Sec-WebSocket-Version']: '13',
            ['Content-Size']: `${message.length}`,
            ['Content-Type']: 'text/plain',
        });
        await this._sendLine(message);
    }

    private async _sendSuccessResponse(): Promise<void> {
        await this._sendStatusLine(101);
        await this._sendHeaders({
            ['Upgrade']: 'websocket',
            ['Connection']: 'Upgrade',
            ['Sec-WebSocket-Accept']: this._computeResponseKey(),
            ['Sec-WebSocket-Version-Server']: '13',
        });
    }

    private _computeResponseKey(): string {
        const requestKey = this._requestHeaders['sec-websocket-key'];
        const rfc6455Magic = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
        const keyRaw = `${requestKey}${rfc6455Magic}`;
        const keyHash = love.data.hash('sha1', keyRaw);

        return love.data.encode('string', 'base64', keyHash);
    }

    //#endregion
}