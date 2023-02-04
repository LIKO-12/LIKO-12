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
    protected readonly requestHeaders: Record<string, string | undefined> = {};

    protected requestLine?: RequestLine;

    constructor(
        protected readonly client: TCPSocket,
    ) {
        try {
            this._readRequestLine();
            this._verifyRequestLine();

            this._readHeaders();
            this._verifyHeaders();
        } catch (err: unknown) {
            const httpError = (err instanceof HTTPError) ? err : new HTTPError(`${err}`, 500);
            this._sendErrorResponse(httpError);
            throw err;
        }

        this._sendSuccessResponse();
    }

    //#region Request Processing

    protected _readLine(): string {
        const [line, err] = this.client.receive('*l');
        if (line === undefined) throw err;
        return line;
    }

    protected _readRequestLine(): void {
        // RFC2616 5.1 Request-Line
        const requestLine = this._readLine();
        const [method, uri, majorRaw, minorRaw] = string.match(requestLine, '^(%a+) (%S+) HTTP/(%d+)%.(%d+)$');

        const major = tonumber(majorRaw), minor = tonumber(minorRaw);
        if (method === undefined || major === undefined || minor === undefined)
            throw new HTTPError('invalid request line');

        this.requestLine = { method: method as HTTPMethod, uri, major, minor };
    }

    protected _verifyRequestLine(): void {
        if (this.requestLine?.method !== 'GET')
            throw new HTTPError('unsupported HTTP method');
        if (this.requestLine?.major !== 1 || this.requestLine?.minor < 1)
            throw new HTTPError('unsupported HTTP version');
    }

    protected _readHeaders(): void {
        // RFC6455 4.2 Server-Side Requirements
        while (true) {
            const line = this._readLine();
            if (line === '') break;

            const [key, value] = string.match(line, '^([^:]+):%s+(.+)$');
            if (key === undefined || value === undefined)
                throw new HTTPError('invalid header line');

            this.requestHeaders[key.toLowerCase()] = value;
        }
    }

    protected _verifyHeaders(): void {
        if (this.requestHeaders['host'] !== 'localhost:50000') throw new HTTPError('non-whitelisted host', 403); // http 403 forbidden
        if (this.requestHeaders['origin'] !== 'http://localhost:8080') throw new HTTPError('non-whitelisted origin', 403); // http 403 forbidden

        if (this.requestHeaders['upgrade']?.toLowerCase() !== 'websocket') throw new HTTPError("invalid/missing 'Upgrade' header");
        if (this.requestHeaders['connection']?.toLowerCase() !== 'upgrade') throw new HTTPError("invalid/missing 'Connection' header");

        if (this.requestHeaders['sec-websocket-version'] !== '13') throw new HTTPError('unsupported websocket version');
        // TODO: send http 426 upgrade required with the right version.

        const wsKeyEncoded = this.requestHeaders['sec-websocket-key'];
        if (wsKeyEncoded === undefined) throw new HTTPError("missing 'Sec-WebSocket-Key' header");

        const wsKey = love.data.decode('string', 'base64', wsKeyEncoded);
        if (wsKey.length !== 16) throw new HTTPError("invalid 'Sec-WebSocket-Key' header");
    }

    //#endregion

    //#region Response Processing

    protected _sendLine(line: string): void {
        const [bytesSend, err] = this.client.send(`${line}\r\n`);
        if (bytesSend === undefined) throw err;
        if (bytesSend !== line.length + 2) throw 'bytes count has not matched!';
    }

    protected _sendStatusLine(code: number): void {
        const reasonPhrase = reasonPhrases[code];
        if (reasonPhrase === undefined) throw `unknown status code (${code})!`;

        this._sendLine(`HTTP/1.1 ${code} ${reasonPhrase}`);
    }

    protected _sendHeaders(headers: Record<string, string>): void {
        for (const [key, value] of pairs(headers))
            this._sendLine(`${key}: ${value}`);
        this._sendLine('');
    }

    protected _sendErrorResponse(err: HTTPError): void {
        const message = `Error: ${err.message}`;

        this._sendStatusLine(err.code);
        this._sendHeaders({
            ['Sec-WebSocket-Version']: '13',
            ['Content-Size']: `${message.length}`,
            ['Content-Type']: 'text/plain',
        });
        this._sendLine(message);
    }

    protected _sendSuccessResponse(): void {
        this._sendStatusLine(101);
        this._sendHeaders({
            ['Upgrade']: 'websocket',
            ['Connection']: 'Upgrade',
            ['Sec-WebSocket-Accept']: this._computeResponseKey(),
            ['Sec-WebSocket-Version-Server']: '13',
        });
    }

    protected _computeResponseKey(): string {
        const requestKey = this.requestHeaders['sec-websocket-key'];
        const rfc6455Magic = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
        const keyRaw = `${requestKey}${rfc6455Magic}`;
        const keyHash = love.data.hash('sha1', keyRaw);

        return love.data.encode('string', 'base64', keyHash);
    }

    //#endregion
}