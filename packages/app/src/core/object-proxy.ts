import { assertParameter } from "./utilities";

const originalObjects = setmetatable(new LuaMap<AnyNotNil, LuaMap>(), { __mode: 'k' });
const patchedMethods = setmetatable(new LuaMap<(...args: any[]) => any, (...args: any[]) => any>, { __mode: 'k' });

function proxyMethod(methodName: string, method: any) {
    if (patchedMethods.has(method)) return patchedMethods.get(method);

    const patched = (key: any, ...args: any[]) => {
        const originalObject = originalObjects.get(key);
        if (originalObject === undefined || originalObject.get(methodName) !== method)
            error('bad object method call: invalid self parameter', 2);

        const result = pcall(method, originalObject, ...args);
        if (result[1] === originalObject) result[1] = key;

        if (result[0]) return $multi(...select(2, ...result));
        error(result[1], 3);
    };

    patchedMethods.set(method, patched);
    return patched;
}

const proxyMetatable: LuaMetatable<any> = {
    __index: function (key) {
        const originalObject = originalObjects.get(this);
        const value = originalObject?.get(key);

        if (type(value) !== 'function') return undefined;
        if (type(key) === 'string' && key[0] === '_') return undefined;

        return proxyMethod(key, value);
    },

    __tostring: function () {
        const originalObject = originalObjects.get(this);
        return `userdata${string.sub(tostring(originalObject), 6, -1)}`;
    },

    __metatable: '<protected>', // this will prevent any setmetatable call.
};

/**
 * FIXME: Document object-proxy.
 */
export function proxy<T>(object: T): T {
    assertParameter(object, 'table', 1, 'proxy');

    const proxyObject = setmetatable({}, proxyMetatable);
    originalObjects.set(proxyObject, object as any);
    return proxyObject as T;
}

export function unproxy<T>(object: T): T {
    return originalObjects.get(object as any) ?? object as any;
}