import { Machine } from "core/machine";

/**
 * Base class for all machine modules.
 */
export default class MachineModule {
    static readonly IS_MACHINE_MODULE = true;

    /**
     * @param _options options table from `options.json`. defaults to `{}`.
     */
    constructor(_machine: Machine, _options: Record<string, any>) { }

    /**
     * Construct an instance of a usable API to be exposed to the machine environment as a global.
     * Named as the module name.
     * 
     * Or return `undefined` if the module has no API.
     * @param machine The same machine during construction.
     */
    createAPI(_machine: Machine): Record<string, any> | undefined {
        return undefined;
    };
}