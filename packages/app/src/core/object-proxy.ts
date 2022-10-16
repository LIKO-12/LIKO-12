import { assertParameter } from './utilities';

const originalObjects: Record<any, any> = setmetatable({}, { __mode: 'k' });
const patchedMethods: Record<any, any> = setmetatable({}, { __mode: 'k' });

function proxyMethod(methodName: string, method: any) {
    if (patchedMethods[method]) return patchedMethods[method];

    const patched = (key: any, ...args: any[]) => {
        const originalObject = originalObjects[key];
        if (originalObject === undefined || originalObject[methodName] !== method)
            error('bad object method call: invalid self parameter', 2);

        const result = pcall(method, originalObject, ...args);
        if (result[1] === originalObject) result[1] = key;

        if (result[0]) return $multi(...select(2, ...result));
        error(result[1], 3);
    };

    patchedMethods[method] = patched;
    return patched;
}

const proxyMetatable: LuaMetatable<any> = {
    __index: function (key) {
        const originalObject = originalObjects[this];
        const value = originalObject[key];

        if (type(value) !== 'function') return undefined;
        if (type(key) === 'string' && key[0] === '_') return undefined;

        return proxyMethod(key, value);
    },

    __tostring: function () {
        const originalObject = originalObjects[this];
        return `userdata${string.sub(tostring(originalObject), 6, -1)}`;
    },

    __metatable: '<protected>', // this will prevent any setmetatable call.
};

/**
 * FIXME: Document object-proxy.
 */
export function proxy<T>(object: T): T {
    assertParameter(object, 'table', 1, 'proxy');

    const proxyObject: any = setmetatable({}, proxyMetatable);
    originalObjects[proxyObject] = object;
    return proxyObject as T;
}

export function unproxy<T>(object: T): T {
    return originalObjects[object] ?? object;
}