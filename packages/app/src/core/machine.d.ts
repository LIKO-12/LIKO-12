/** @noSelfInFile */
import EventsEmitter from "core/events-emitter";
import MachineModule from "./machine-module";
export default class Machine {
    readonly events: EventsEmitter;
    private _environmentBox;
    private readonly _modules;
    private _initializingModules;
    /**
     * Machine program thread (when running)
     */
    private _thread?;
    constructor(modulesNames: string[], modulesOptions: Record<string, any>);
    /**
     * @throws when a program is already loaded in the machine.
     */
    load(program: (...args: any[]) => any): this;
    /**
     * @throws if no program is loaded into the machine.
     */
    resume(...args: any[]): void;
    isSuspended(): boolean;
    isRunning(): boolean;
    isDead(): boolean;
    getStatus(): 'running' | 'suspended' | 'dead';
    /**
     * @throws if no program is loaded into the machine.
     */
    unload(): this;
    /**
     * @throws if a program is loaded into the machine.
     */
    resetEnvironment(): this;
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
    resolveModule<M extends MachineModule>(moduleName: string): M | undefined;
    private _loadModules;
    private _exposeModulesAPIs;
}
//# sourceMappingURL=machine.d.ts.map