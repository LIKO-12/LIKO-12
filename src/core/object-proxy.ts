const originalObjects: Record<any, any> = setmetatable({}, { __mode: 'k' });
const patchedMethods: Record<any, any> = setmetatable({}, {
    __index: function (this: any, method: any) {
        const patched = (key: any, ...args: any[]) => {
            const originalObject = originalObjects[key];
            if (originalObject === undefined) error('call using : instead of .', 2);
            // TODO: Find a better error message that's more clear (check love's one).
            
            const result = pcall(method, originalObject, ...args);
            if (result[1] === originalObject) result[1] = key;
            
            if (result[0]) return $multi(...select(2, ...result));
            error(result[1], 3);
        };

        (this as any)[method] = patched;
        return patched;
    },

    __mode: 'k',
});

const proxyMetatable: LuaMetatable<any> = {
    __index: function(key) {
        const originalObject = originalObjects[this];
        const value = originalObject[key];

        if (type(value) !== 'function') return undefined;
        if (type(key) === 'string' && key[0] === '_') return undefined;

        return patchedMethods[value];
    },

    __tostring: function() {
        const originalObject = originalObjects[this];
        return `userdata${string.sub(tostring(originalObject), 6, -1)}`;
    },

    __metatable: '<protected>', // this will prevent any setmetatable call.
};

/**
 * FIXME: Document object-proxy.
 */
export function proxy<T>(object: T): T {
    const proxyObject: any = setmetatable({}, proxyMetatable);
    originalObjects[proxyObject] = object;
    return proxyObject as T;
}