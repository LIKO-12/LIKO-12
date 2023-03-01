import { JSONRPC, JSONRPCErrorResponse, JSONRPCMethod, JSONRPCServer, JSONRPCSuccessResponse } from '@liko-12/tstl-json-rpc/out';

import { loveEvents } from 'core/love-events';
import { NULL } from 'core/json-adapter';
import { MachineOptions } from 'core/machine';

import { WebSocketConnection } from 'core/websocket/connection';
import { WebSocketServer } from 'core/websocket/server';

import { GameRuntime } from './game-runtime';
import { GameRuntimeServerOverlay } from './game-runtime-server-overlay';

export class GameRuntimeServer {
    private readonly runtime: GameRuntime;
    private readonly socket: WebSocketServer;
    private readonly rpc: JSONRPCServer;

    private readonly overlay: GameRuntimeServerOverlay;

    constructor(machineOptions: MachineOptions) {
        this.runtime = new GameRuntime(machineOptions);
        this.socket = new WebSocketServer('127.0.0.1', 50_000);
        this.rpc = new JSONRPCServer();
        
        this.registerRPCMethods();
        this.registerSocketListeners();
        
        this.socket.start();
        loveEvents.on('quit', () => this.socket.stop());
        
        this.overlay = new GameRuntimeServerOverlay();
        print('Server ready and running on ws://127.0.0.1:50000/');
    }

    run(script: string): void {
        this.runtime.run(script);
        love.window.requestAttention(true);
    }

    private registerRPCMethods() {
        this.addRPCMethod('echo', (text: string) => text);
        this.addRPCMethod('log', (message: string) => print('Message from RPC:', message));
        this.addRPCMethod('run', (script: string) => this.run(script));
    }

    private registerSocketListeners() {
        this.socket.on('connection', (connection: WebSocketConnection) => {
            connection.on('open', () => {
                print('Received a new connection.');
            });

            connection.on('message', (message: string, _binary: boolean) => {
                this.rpc.receiveJSON(message).then((response) => {
                    connection.send(JSON.stringify(response));
                });
            });

            connection.on('close', (code: number | undefined, reason: string | undefined) => {
                if (code === undefined) print('Connection closed in a dirty state.');
                else print(`Connection closed with code (${code})`, reason ? `and message "${reason}"` : '');
            });
        });
    }

    private addRPCMethod(name: string, method: (...args: any[]) => any): void {
        this.rpc.addMethodAdvanced(name, GameRuntimeServer.wrapRPCMethod(method));
    }

    private static wrapRPCMethod(method: (...args: any[]) => any): JSONRPCMethod {
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
}
