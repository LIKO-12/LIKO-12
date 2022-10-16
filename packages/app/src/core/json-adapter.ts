import * as json from '../lib/json';

/**
 * An adapter to provide JS compatible JSON API, by using a pure Lua implementation to provide it.
 */
const adapter: typeof JSON = {
    parse: function (text: string, reviver?: ((this: any, key: string, value: any) => any) | undefined) {
        // note: it can be actually polyfilled (implemented manually).
        if (reviver) throw new Error('unsupported: the "reviver" parameter is not supported by the implementation of the current environment.');
        return json.decode(text);
    },
    stringify: function (value: any, replacer?: ((this: any, key: string, value: any) => any) | ((number | string)[] | null), space?: string | number): string {
        if (replacer) throw new Error('unsupported: the "replacer" parameter is not supported by the implementation of the current environment.');

        if (space === undefined) return json.encode(value);
        return json.encode_pretty(value, undefined, {
            indent: typeof space === 'number' ? ' '.repeat(space) : space,
        });
    },
    [Symbol.toStringTag]: ""
};

(_G as any).JSON = adapter;