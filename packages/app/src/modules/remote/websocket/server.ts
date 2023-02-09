import { EventsEmitter } from 'core/events-emitter';
import * as socket from 'socket';
import { addJob } from './async-jobs-worker';
import { WebSocketConnection } from './connection';

export type ConnectionEventHandler = (connection: WebSocketConnection) => void;

export class WebSocketServer extends EventsEmitter {
    private server: TCPSocket | undefined;

    constructor(
        public readonly address: string,
        public readonly port: number,
    ) {
        super();
    }

    start(): void {
        if (this.server) throw 'The server is already running.';

        const [server, serverError] = socket.bind(this.address, this.port);
        if (!server) throw serverError;

        // use unblocking mode.
        server.settimeout(0);
        this.server = server;

        this.loop().catch((err) => {
            server.close();
            throw err;
        });
    }

    stop(): void {
        const server = this.server;
        if (!server) throw 'The server is not running.';
        server.close();
    }

    private async loop() {
        while (true) this.emit('connection', new WebSocketConnection(await this.accept()));
    }

    private accept(): Promise<TCPSocket> {
        const server = this.server;
        if (!server) throw 'invalid state!';

        return new Promise((resolve, reject) => {
            addJob(() => {
                const [client, clientError] = server.accept();
                if (clientError === 'timeout') return false;

                client?.settimeout(0);

                if (client) resolve(client);
                else reject(clientError);

                return true;
            });
        });
    }
}