import { loveEvents } from 'core/love-events';
import { Machine } from 'core/machine';
import { MachineModule } from 'core/machine-module';
import { assertOption } from 'core/utilities';
import { WebSocketConnection } from './websocket/connection';
import { WebSocketServer } from './websocket/server';

export interface RemoteOptions {
    listenAddress?: string,
    listenPort?: number,
}

export default class Remote extends MachineModule {
    constructor(private machine: Machine, options: RemoteOptions) {
        super(machine, options);

        const server = new WebSocketServer(
            assertOption(options.listenAddress ?? '127.0.0.1', 'listenAddress', 'string'),
            assertOption(options.listenPort ?? 50_000, 'listenPort', 'number'),
        );

        server.start();
        loveEvents.on('quit', () => server.stop());

        server.on('connection', (connection: WebSocketConnection) => {
            connection.on('open', () => {
                connection.send('Greetings from server!');
            });

            connection.on('message', (message: string, binary: boolean) => {
                connection.send(`S${message}`, binary);
            });
        });
    }
}
