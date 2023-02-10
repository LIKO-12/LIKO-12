import { loveEvents } from 'core/love-events';
import { Machine } from 'core/machine';
import { MachineModule } from 'core/machine-module';
import { assertOption } from 'core/utilities';
import Events from 'modules/events';
import { WebSocketConnection } from './websocket/connection';
import { WebSocketServer } from './websocket/server';

export interface RemoteOptions {
    listenAddress?: string,
    listenPort?: number,
}

export default class Remote extends MachineModule {
    constructor(private machine: Machine, options: RemoteOptions) {
        super(machine, options);
        
        const events = machine.resolveModule<Events>('events')!;

        const server = new WebSocketServer(
            assertOption(options.listenAddress ?? '127.0.0.1', 'listenAddress', 'string'),
            assertOption(options.listenPort ?? 50_000, 'listenPort', 'number'),
        );

        server.start();
        loveEvents.on('quit', () => server.stop());

        server.on('connection', (connection: WebSocketConnection) => {
            connection.on('open', () => {
                print('Received a new connection.');
            });

            connection.on('message', (message: string, binary: boolean) => {
                events.pushEvent('remote_message', message, binary);
                // TODO: A properly encapsulated solution for remote messaging.
            });

            connection.on('close', (code: number | undefined, reason: string | undefined) => {
                if (code === undefined) print('Connection closed in a dirty state.');
                else print(`Connection closed with code (${code})`, reason ? `and message "${reason}"` : '');
            });
        });
    }
}
