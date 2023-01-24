// Protect the standard string metatable.
(getmetatable('') ?? {}).__metatable = {};

/**
 * Escaped safe call. When the called method fails.
 * The error is propagated 1 level behind the caller.
 * Useful for encapsulating and patching existing functions
 * while keeping their error messages.
 */
function ecall(func: (...args: any[]) => any, ...args: any[]) {
    const result = pcall(func, ...args);
    if (result[1]) return select(2, ...result);
    error(result[2], 3);
}

const escapeCharacter = String.fromCharCode(0x1B);

/**
 * Checks whether the data might be Lua bytecode or not.
 */
function isBytecode(data: unknown) {
    if (typeof data !== 'string') return false;
    return string.sub(data, 1, 1) === escapeCharacter;
}

type Environment = Record<any, any>;

export class EnvironmentBox {
    private _protectedEnvironments = new LuaSet<object>();
    private _protectedThreads = new LuaSet<LuaThread>();

    private _externalYield = true;

    private _G: Environment = {};

    constructor() {
        this._G._G = this._G; // An explicitly infinite containment relationship. How rare.

        this._exposeSafeStandardLibraries();
        this._exposeSafeSubStandardLibraries();
        this._exposePatchedStandardLibraries();
    }

    /**
     * Apply the environment on the provided function.
     * 
     * (Sets the globals of the function).
     */
    apply(func: (...args: any[]) => any) {
        setfenv(func, this._G);
        return this;
    }

    /**
     * Protects an environment/globals from being accessed by the encapsulated code.
     */
    protectEnvironment(environment: Environment) {
        this._protectedEnvironments.add(environment);
        return this;
    }

    unprotectEnvironment(environment: Environment) {
        this._protectedEnvironments.delete(environment);
        return this;
    }

    /**
     * Protects a thread from being yielded or accessed by the encapsulated code.
     * While still allowing to yield out of them by a yield from non-encapsulated code.
     * Such a yield would be called an "external yield" and would propagate through all
     * the unprotected threads running within a protected one.
     */
    protectThread(thread: LuaThread) {
        this._protectedThreads.add(thread);
        return this;
    }

    unprotectThread(thread: LuaThread) {
        this._protectedThreads.delete(thread);
        return this;
    }

    /**
     * Expose a group of values into the global scope of the environment.
     */
    expose(globals: Environment) {
        for (const [key, value] of pairs(globals))
            if (value !== undefined) rawset(this._G, key, value);
        return this;
    }

    /**
     * Expose standard functions such as `error`, `pairs`, etc...
     * And other standards libs such as `string` and `table`.
     */
    private _exposeSafeStandardLibraries() {
        this.expose({
            _VERSION: _VERSION,
            assert: assert,
            error: error,
            print: print,
            ipairs: ipairs,
            pairs: pairs,
            next: next,
            pcall: pcall,
            select: select,
            tonumber: tonumber,
            tostring: tostring,
            type: type,
            unpack: unpack,
            xpcall: xpcall,
            setmetatable: setmetatable,
            getmetatable: getmetatable,
            rawget: rawget,
            rawset: rawset,
            rawequal: rawequal,
            string: {
                byte: string.byte,
                char: string.char,
                find: string.find,
                format: string.format,
                gmatch: string.gmatch,
                gsub: string.gsub,
                len: string.len,
                lower: string.lower,
                match: string.match,
                rep: string.rep,
                reverse: string.reverse,
                sub: string.sub,
                upper: string.upper,
            },
            table: {
                insert: table.insert,
                maxn: table.maxn,
                remove: table.remove,
                sort: table.sort,
                concat: table.concat,
            },
            math: {
                abs: math.abs,
                acos: math.acos,
                asin: math.asin,
                atan: math.atan,
                atan2: math.atan2,
                ceil: math.ceil,
                cos: math.cos,
                cosh: math.cosh,
                deg: math.deg,
                exp: math.exp,
                floor: math.floor,
                fmod: math.fmod,
                frexp: math.frexp,
                huge: math.huge,
                ldexp: math.ldexp,
                log: math.log,
                log10: math.log10,
                max: math.max,
                min: math.min,
                modf: math.modf,
                pi: math.pi,
                pow: math.pow,
                rad: math.rad,
                random: math.random,
                randomseed: math.randomseed,
                sin: math.sin,
                sinh: math.sinh,
                sqrt: math.sqrt,
                tan: math.tan,
                tanh: math.tanh,
            },
            os: {
                time: os.time,
                difftime: os.difftime,
                clock: os.clock,
                date: os.date,
            },
        });
    }

    /**
     * Expose sub-standard libraries which are `bit` (from luaJIT)` and `utf8`.
     */
    private _exposeSafeSubStandardLibraries() {
        this.expose({
            bit: {
                cast: (bit as any).cast,
                bnot: bit.bnot,
                band: bit.band,
                bor: bit.bor,
                bxor: bit.bxor,
                lshift: bit.lshift,
                rshift: bit.rshift,
                arshift: bit.arshift,
                tobit: bit.tobit,
                tohex: bit.tohex,
                rol: bit.rol,
                ror: bit.ror,
                bswap: bit.bswap,
            },
            utf8: {
                char: utf8.char,
                charpattern: utf8.charpattern,
                codes: utf8.codes,
                codepoint: utf8.codepoint,
                len: utf8.len,
                offset: utf8.offset,
            },
        });
    }

    /**
     * Expose patched standard libraries which respect the sandbox encapsulation.
     */
    private _exposePatchedStandardLibraries() {
        const patchedResume = (...args: any[]) => {
            // Propagate a transparent yield when it happens.
            const [result] = ecall(coroutine.resume, ...args);
            if (this._externalYield) return (ecall as any)(patchedResume, coroutine.yield(unpack(result)));
            return result;
        }

        this.expose({
            getfenv: (func: any) => {
                // Disallow access to protected environments.
                const [env] = ecall(getfenv, func);
                if (this._protectedEnvironments.has(env)) return undefined;
                return env;
            },
            setfenv: (func: any, env: any) => {
                // Disallow kidnapping functions with protected environments.
                // (Disallow replacing their protected environment)
                const [existingEnv] = ecall(getfenv, func);
                if (this._protectedEnvironments.has(existingEnv)) return;
                return ecall(setfenv, func, env);
            },
            loadstring: (data: unknown, chunkName: any) => {
                // Disallow loading untrusted Lua bytecode.
                // And set the environment of the loaded code.
                if (isBytecode(data)) return error('(binary): cannot load bytecode');
                const [chunk, err] = ecall(loadstring, data, chunkName);
                if (chunk) setfenv(chunk, this._G);
                return $multi(chunk, err);
            },
            load: (func: any, chunkName: any) => {
                // Disallow loading untrusted Lua bytecode.
                // And set the environment of the loaded code.
                let firstChunk = true;
                const wrappedFunc = (...args: any[]) => {
                    const [chunk] = ecall(func, ...args);

                    if (firstChunk && typeof chunk === 'string') {
                        if (chunk.length !== 0) firstChunk = false;
                        if (isBytecode(chunk)) return error('(binary): cannot load bytecode');
                    }

                    return chunk;
                }

                const [chunk, err] = ecall(load, wrappedFunc, chunkName);
                if (chunk) setfenv(chunk, this._G);
                return $multi(chunk, err);
            },
            coroutine: {
                create: coroutine.create,
                status: coroutine.status,
                resume: patchedResume,
                running: () => {
                    // Disallow access to protected threads.
                    const thread = coroutine.running();
                    if (thread !== undefined && this._protectedThreads.has(thread)) return undefined;
                    return thread;
                },
                yield: (...args: any[]) => {
                    // Prevent yielding out of a protected thread.
                    const thread = coroutine.running();

                    if (thread !== undefined && this._protectedThreads.has(thread))
                        return error('attempt to yield across C-call boundary');

                    // Set the flag to indicate this is an internal yield.
                    this._externalYield = false;
                    const results = ecall(coroutine.yield, ...args);
                    this._externalYield = true;

                    return results;
                },
                wrap: (func: any) => {
                    // Use the patched coroutine.resume, otherwise a C version is called.
                    const thread = coroutine.create(func);

                    return (...args: any[]) => {
                        const results = patchedResume(thread, ...args);
                        if (results[1]) return select(2, unpack(results));
                        return error(results[2]);
                    };
                },
            }
        });
    }
}