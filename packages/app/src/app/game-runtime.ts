import { Machine, MachineOptions } from 'core/machine';
import { options } from 'core/options';

export class GameRuntime {
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
