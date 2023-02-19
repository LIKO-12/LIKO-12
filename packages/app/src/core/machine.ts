import { EnvironmentBox } from "@liko-12/environment-box";

import { EventsEmitter } from "core/events-emitter";
import { MachineModule } from "./machine-module";

export interface MachineOptions {
    /**
     * **⚠️ UNSAFE ⚠️** Whether to expose the standard `debug` api or not.
     * Disabled by default because it allows to escape the sandbox.
     */
    debugMode?: boolean;
}

export class Machine {
    readonly events = new EventsEmitter();

    private _environmentBox!: EnvironmentBox; // Initialized by the constructor's call to `resetEnvironment`.

    private readonly _modules: Record<string, MachineModule> = {};
    private _initializingModules = false;

    /**
     * Machine program thread (when running)
     */
    private _thread?: LuaThread;

    constructor(
        modulesNames: string[],
        modulesOptions: Record<string, any>,
        private globalModules: string[],
        private machineOptions: MachineOptions = {},
    ) {
        this._loadModules(modulesNames, modulesOptions);
        this.resetEnvironment();
    }

    /**
     * @throws when a program is already loaded in the machine.
     */
    load(program: (...args: any[]) => any) {
        if (this._thread) throw new Error('a program is already loaded');

        this._environmentBox.apply(program);
        const thread = coroutine.create(program);
        this._environmentBox.protectThread(thread);
        this._thread = thread;

        return this;
    }

    /**
     * @throws if no program is loaded into the machine.
     */
    resume(...args: any[]) {
        if (!this._thread) throw new Error('no program is loaded to be resumed');

        this.events.emit('resumed');
        const [ok, message] = coroutine.resume(this._thread, ...args);
        assert(ok, message);
        this.events.emit('suspended');

        if (coroutine.status(this._thread) === 'dead') this.unload();
        // TODO: Execute a BSOD program with the same environment. This would allow doing crash dumps and saving user data.
    }

    isSuspended() {
        if (!this._thread) return false;
        return coroutine.status(this._thread) === 'suspended';
    }

    isRunning() {
        if (!this._thread) return false;
        const status = coroutine.status(this._thread);
        return status === 'running' || status === 'normal';
    }

    isDead() {
        if (!this._thread) return true;
        return coroutine.status(this._thread) === 'dead';
    }

    getStatus(): 'running' | 'suspended' | 'dead' {
        if (!this._thread) return 'dead';
        const status = coroutine.status(this._thread);
        return status === 'normal' ? 'running' : status;
    }

    /**
     * @throws if no program is loaded into the machine.
     */
    unload() {
        if (!this._thread) throw new Error('no program is loaded');
        this._environmentBox.unprotectThread(this._thread);
        this._thread = undefined;

        return this;
    }

    /**
     * Applies the machine's environment on a function.
     */
    applyEnvironment(method: (args: unknown[]) => unknown): void {
        this._environmentBox.apply(method);
    }

    /**
     * @throws if a program is loaded into the machine.
     */
    resetEnvironment() {
        if (this._thread) throw new Error('forbidden while a program is loaded');

        this._environmentBox = new EnvironmentBox();
        this._environmentBox.protectEnvironment(_G);

        if (this.machineOptions.debugMode) this._environmentBox.expose({ debug });

        this._exposeModulesAPIs();
        return this;
    }

    /**
     * Resolve a module, for interoperability between machine modules.
     * 
     * When done during module initialization, the initialization is paused until the dependency is loaded.
     * And thus it's considered a required dependency for the module.
     * 
     * But when done post-initialization, nil is returned if a module was not loaded.
     * Thus considered an optional late dependency.
     * 
     * The pausing during initialization is achieved by initializing each module within a thread (coroutine).
     */
    resolveModule<M extends MachineModule>(moduleName: string): M | undefined {
        if (this._initializingModules) while (!this._modules[moduleName]) coroutine.yield(moduleName);
        return this._modules[moduleName] as M;
    }

    private _loadModules(modulesNames: string[], modulesOptions: Record<string, any>) {
        const pending: Record<string, LuaThread> = {};

        /*
        This is an approach for resolving modules dependencies using Lua threads (coroutines).
        Where the modules should use `Machine.resolveModule` for resolving their required dependencies.
        When a dependency is requested, the initialization thread yields to be resumed at the next iteration.
        In the hope that the module it requested got loaded, otherwise it retries at the next iteration.

        With (maximum iterations count = modules count) it's guaranteed that if a dependency is resolvable
        it would have been already resolved. Any remaining dependencies would be due to:
        - either not loaded module (not configured to be loaded or doesn't exist).
        - or deadlocked dependency (two modules depending on each other).
        The error message in this case should clarify the situation.

        1. Loads each module's code.
        2. Creates a thread for initializing an instance of each module.
        3. Each thread is executed in the next section below for initializing the dependencies.
        */
        for (const moduleName of modulesNames) {
            const moduleOptions = modulesOptions[moduleName] ?? {};

            const modulePath = `modules.${moduleName}`;
            const Module: typeof MachineModule = require(modulePath).default;
            if (!Module.IS_MACHINE_MODULE)
                throw new Error(`invalid module '${moduleName}' should be a subclass of core/MachineModule`);

            const thread = coroutine.create(() => this._modules[moduleName] = new Module(this, moduleOptions));
            pending[moduleName] = thread;
        }

        const unresolved: string[] = [];

        this._initializingModules = true; // For Machine.resolveModule to yield when resolving an unloaded dependency.

        // Notice the 1 extra iteration for looking up what's the stuck dependencies and forming the error message.
        for (let i = modulesNames.length; i >= 0; i--) {
            for (const moduleName in pending) {
                const thread = pending[moduleName];
                if (!thread) continue;

                const [ok, requestedModule] = coroutine.resume(thread);
                assert(ok, requestedModule);

                if (coroutine.status(thread) === 'dead') delete pending[moduleName];

                if (i === 0 && requestedModule)
                    unresolved.push(`(${requestedModule} <- ${moduleName})`);
            }
        }

        this._initializingModules = false;

        if (unresolved.length !== 0)
            throw new Error(`failed to resolve modules dependencies: ${unresolved.join(', ')}`);
    }

    private _exposeModulesAPIs() {
        const apis: Record<string, Record<string, any> | undefined> = {};
        const globals: Record<string, any> = { liko: apis };

        for (const moduleName in this._modules) {
            const api = this._modules[moduleName].createAPI(this);
            apis[moduleName] = api;

            if (!this.globalModules.includes(moduleName)) continue;
            for (const name in api) {
                if (globals[name] !== undefined) throw new Error(`Multiple global modules define the entry '${name}'`);
                globals[name] = api[name];
            }
        }

        this._environmentBox.expose(globals);
    }
}