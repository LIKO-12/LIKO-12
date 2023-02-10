import { JSONRPC, JSONRPCErrorResponse, JSONRPCMethod, JSONRPCServer, JSONRPCSuccessResponse } from '@liko-12/tstl-json-rpc';
import { NULL } from 'core/json-adapter';
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

function wrapRPCMethod(method: (...args: any[]) => any): JSONRPCMethod {
    return (request) => {
        try {
            return Promise.resolve<JSONRPCSuccessResponse>({
                jsonrpc: JSONRPC,
                id: request.id ?? null,
                result: method(...(request.params ?? [])) ?? NULL,
            });
        } catch (err) {
            return Promise.resolve<JSONRPCErrorResponse>({
                jsonrpc: JSONRPC,
                id: request.id ?? null,
                error: {
                    code: 0,
                    message: tostring(err),
                },
            });
        }
    };
}

export default class Remote extends MachineModule {
    constructor(private machine: Machine, options: RemoteOptions) {
        super(machine, options);
        
        const events = machine.resolveModule<Events>('events')!;

        const server = new WebSocketServer(
            assertOption(options.listenAddress ?? '127.0.0.1', 'listenAddress', 'string'),
            assertOption(options.listenPort ?? 50_000, 'listenPort', 'number'),
        );

        const rpcServer = new JSONRPCServer();

        rpcServer.addMethodAdvanced('echo', wrapRPCMethod((text: string) => text));
        rpcServer.addMethodAdvanced('log', wrapRPCMethod((message: string) => print('Message from RPC:', message)));
        rpcServer.addMethodAdvanced('run', wrapRPCMethod((script: string) => events.pushEvent('run', script)));

        server.start();
        loveEvents.on('quit', () => server.stop());

        server.on('connection', (connection: WebSocketConnection) => {
            connection.on('open', () => {
                print('Received a new connection.');
            });

            connection.on('message', (message: string, _binary: boolean) => {
                rpcServer.receiveJSON(message).then((response) => {
                    connection.send(JSON.stringify(response));
                });
            });

            connection.on('close', (code: number | undefined, reason: string | undefined) => {
                if (code === undefined) print('Connection closed in a dirty state.');
                else print(`Connection closed with code (${code})`, reason ? `and message "${reason}"` : '');
            });
        });
    }
}
