/**
 * Bootstraps the standard LIKO-12 application which runs a single machine.
 */

import { options } from 'core/options';
import { loveEvents } from 'core/love-events';
import { Machine, MachineOptions } from 'core/machine';
import { WebSocketServer } from 'core/websocket/server';
import { JSONRPC, JSONRPCErrorResponse, JSONRPCMethod, JSONRPCServer, JSONRPCSuccessResponse } from '@liko-12/tstl-json-rpc/out';
import { NULL } from 'core/json-adapter';
import { WebSocketConnection } from 'core/websocket/connection';

// TODO: Setup eslint for the project.
// TODO: Create eslint rule to warn about missing "validateParameters" call.
// TODO: Create eslint rule for returning a non-proxy object.
// TODO: Create eslint rule for possibly object-exposing actions.
// TODO: Apply the eslint rule to not use default exports (except in MachineModules).
// TODO: Figure out a way to type the events emitter.
// TODO: Figure out a way to document the emitted events.
// TODO: Make sure that the repository satisfies the open-source community standards.

math.randomseed(os.time());

class GameRuntime {
    private readonly machine: Machine;

    constructor(machineOptions?: MachineOptions) {
        this.machine = new Machine(options.modules, options.options, options.globals, machineOptions);
    }

    run(script: string): void {
        if (!this.machine.isDead()) {
            this.machine.unload();
            print('Terminated already running game.');
        }

        print('Loading & Running the received game.');

        const [gameProgram, compileError] = loadstring(script, 'game.lua');
        if (!gameProgram) {
            print('Failed to compile:', compileError);
            return;
        }

        this.machine.applyEnvironment(gameProgram);

        const kernelProgram = GameRuntime.loadKernel();
        this.machine.applyEnvironment(kernelProgram);

        const program = () => {
            kernelProgram();
            gameProgram();

            const eventLoop = (_G as any)['_eventLoop'] as unknown;
            if (typeof eventLoop === 'function') eventLoop();
        };

        this.machine.load(program).resume();
    }

    private static loadKernel(): () => unknown {
        const [kernelScript, errorMessage] = love.filesystem.read('res/kernel/init.lua');
        if (!kernelScript) throw new Error(`Failed to read kernel script: ${errorMessage}`);

        const [kernel, compileError] = loadstring(kernelScript, 'kernel.lua');
        if (!kernel) throw new Error(`Failed to compile kernel script: ${compileError}`);

        return kernel;
    }
}

class GameRuntimeServer {
    private readonly runtime: GameRuntime;
    private readonly socket: WebSocketServer;
    private readonly rpc: JSONRPCServer;

    constructor(machineOptions: MachineOptions) {
        this.runtime = new GameRuntime(machineOptions);
        this.socket = new WebSocketServer('127.0.0.1', 50_000);
        this.rpc = new JSONRPCServer();

        this.registerRPCMethods();
        this.registerSocketListeners();

        this.socket.start();
        loveEvents.on('quit', () => this.socket.stop());

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

loveEvents.on('load', (args: string[]) => {
    io.write('\x1B[2J\x1B[3J\x1B[1;1H'); // reset the terminal using ANSI escape sequence.

    new GameRuntimeServer({
        debugMode: args.includes('--debug')
    });
});

loveEvents.on('keypressed', (key: string) => {
    if (key !== '\\') return;
    love.event.quit('restart');
});
