
/**
 * An alternative to Lua's assert that's more convenient to use at the cost of some type safety.
 */
export function assert<T>(...args: any[]): T;
export function assert(value: unknown, message: unknown): unknown {
    if (value === undefined || value === false) throw new Error(tostring(message ?? 'assertion failed'));
    return value;
}

export function pullEvents(): LuaIterable<LuaMultiReturn<[string, ...any]>> {
    const events = liko.events;
    if (!events) throw 'events module is not loaded!';

    return (() => events.pull()) as any;
}