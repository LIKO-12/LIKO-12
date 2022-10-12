/// <reference types="lua-types/jit" />
/** @noSelfInFile */
declare type Environment = Record<any, any>;
export default class EnvironmentBox {
    private _protectedEnvironments;
    private _protectedThreads;
    private _externalYield;
    private _G;
    constructor();
    /**
     * Apply the environment on the provided function.
     *
     * (Sets the globals of the function).
     */
    apply(func: (...args: any[]) => any): this;
    /**
     * Protects an environment/globals from being accessed by the encapsulated code.
     */
    protectEnvironment(environment: Environment): this;
    unprotectEnvironment(environment: Environment): this;
    /**
     * Protects a thread from being yielded or accessed by the encapsulated code.
     * While still allowing to yield out of them by a yield from non-encapsulated code.
     * Such a yield would be called an "external yield" and would propagate through all
     * the unprotected threads running within a protected one.
     */
    protectThread(thread: LuaThread): this;
    unprotectThread(thread: LuaThread): this;
    /**
     * Expose a group of values into the global scope of the environment.
     */
    expose(globals: Environment): this;
    /**
     * Expose standard functions such as `error`, `pairs`, etc...
     * And other standards libs such as `string` and `table`.
     */
    private _exposeSafeStandardLibraries;
    /**
     * Expose sub-standard libraries which are `bit` (from luaJIT)` and `utf8`.
     */
    private _exposeSafeSubStandardLibraries;
    /**
     * Expose patched standard libraries which respect the sandbox encapsulation.
     */
    private _exposePatchedStandardLibraries;
}
export {};
//# sourceMappingURL=environment-box.d.ts.map