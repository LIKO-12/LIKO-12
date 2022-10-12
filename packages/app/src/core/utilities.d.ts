/** @noSelfInFile */
/**
 * Lua style type assertion messages.
 *
 * `"bad argument #{pos} to '{methodName}' ({type} expected, got {type})"`
 *
 * @returns The value itself if it was valid.
 * @throws When the value doesn't match the expected type.
 */
export declare function assertParameter<V>(value: V, expectedType: string, position: number, methodName: string): V;
/**
 * Lua style type assertion messages. For parameters with multiple types allowed (mixed).
 *
 * Only 4 types are allowed. If more are needed, assert it manually.
 *
 * `"bad argument #{pos} to '{methodName}' (invalid option)"`
 *
 * @returns The value itself if it was valid.
 * @throws When the value doesn't match the expected type.
 */
export declare function assertMixedParameter<V>(value: V, position: number, methodName: string, type1: string, type2?: string, type3?: string, type4?: string): V;
/**
 * Assert the value of an option.
 *
 * Use to validate the type of MachineModule options table fields.
 *
 * Check a module with options to see it in action, like the screen module.
 *
 * @returns The value itself if it was valid.
 * @throws When the value doesn't match the expected type.
 */
export declare function assertOption<V>(value: V, optionName: string, type1: string, type2?: string, type3?: string, type4?: string): V;
declare type TypeToken = 'number' | 'string' | 'boolean' | 'function' | 'undefined' | 'null';
declare type TypesTokens = (TypeToken | TypesTokens)[];
declare type Parameter = [value: unknown, name: string, tokens: TypesTokens];
/**
 * https://github.com/Rami-Sabbagh/ts-inject-parameters-metadata
 * TODO: Document this.
 */
export declare function validateParameters(): void;
export declare function validateParameters(methodName: string | undefined, parameters: Parameter[]): void;
/**
 * Ensures that a number is within a specific range and floors it optionally.
 */
export declare function clamp(value: number, min?: number, max?: number, floor?: boolean): number;
/**
 * Escaped safe call. When the called method fails.
 * The error is propagated 1 level behind the caller.
 * Useful for encapsulating and patching existing functions
 * while keeping their error messages.
 */
export declare function escapedCall<T = any>(func: (...args: any[]) => any, ...args: any[]): T;
export {};
//# sourceMappingURL=utilities.d.ts.map