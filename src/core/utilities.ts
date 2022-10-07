/**
 * Lua style type assertion messages.
 * 
 * `"bad argument #{pos} to '{methodName}' ({type} expected, got {type})"`
 * 
 * @returns The value itself if it was valid.
 * @throws When the value doesn't match the expected type.
 */
export function assertParameter<V>(value: V, expectedType: string, position: number, methodName: string): V {
    const valueType = type(value);

    if (valueType !== expectedType)
        error(`bad argument #${position} to '${methodName}' (${expectedType} expected, got ${valueType === 'nil' ? 'no value' : valueType})`, 3);

    return value;
}

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
export function assertMixedParameter<V>(value: V, position: number, methodName: string, type1: string, type2?: string, type3?: string, type4?: string): V {
    /*
    Limiting to 4 possible types allows to simplify the implementation and not use arrays in it.
    This could give a micro optimization and help do less stress on the garbage collector.

    And reasonably, more than 4 types for a parameter would rather have it set to any type
    or check for rejected ones instead.
    */
    const valueType = type(value);

    if (valueType !== type1 && valueType !== type2 && valueType !== type3 && valueType !== type4)
        error(`bad argument #${position} to '${methodName}' (invalid option)`, 3);

    return value;
}

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
export function assertOption<V>(value: V, optionName: string, type1: string, type2?: string, type3?: string, type4?: string): V {
    // Follows the same limited types count note of utilities.assertMixedParameter.
    const valueType = type(value);

    if (valueType !== type1 && valueType !== type2 && valueType !== type3 && valueType !== type4) {
        if (valueType === 'nil') error(`options.${optionName} is not set`, 2);
        else error(`options.${optionName} is invalid`, 2);
    }

    return value;
}

type TypeToken = 'number' | 'string' | 'boolean' | 'function' | 'undefined' | 'null';
type TypesTokens = (TypeToken | TypesTokens)[];
type Parameter = [value: unknown, name: string, tokens: TypesTokens];

function formatTypes(tokens: TypesTokens) {
    const simplified = tokens.map(token => typeof token === 'string' ? token : 'table');
    const lastToken = simplified.pop();

    if (simplified.length === 0) return lastToken;
    return `${simplified.join(', ')} or ${lastToken}`;
}

function validateParameter(methodName: string, position: number, value: unknown, name: string, tokens: TypesTokens): string | void {
    if (tokens.length === 0) return;

    for (const token of tokens) {
        if (token === 'undefined' && value === undefined) return;
        if (token === 'null' && value === null) return;
        if (typeof value === token) return;

        if (typeof token !== 'string' && typeof value === 'object') {
            for (const [key, entry] of pairs(value as any)) {
                const errMessage = validateParameter(methodName, position, entry, `${name}[${tostring(key)}]`, token);
                if (errMessage !== undefined) return errMessage;
            }

            return;
        }

        return `bad argument #${position} '${name}' to ${methodName} (${formatTypes(tokens)} expected, got ${type(value)})`;
    }
}

/**
 * https://github.com/Rami-Sabbagh/ts-inject-parameters-metadata
 * TODO: Document this.
 */
export function validateParameters(): void;
export function validateParameters(methodName: string | undefined, parameters: Parameter[]): void;
export function validateParameters(methodName?: string | undefined, parameters?: Parameter[]) {
    if (!parameters) throw new Error('the parameters have not been resolved by the transformer.');
    const formattedMethodName = `'${methodName ?? '(no name)'}'`;

    for (let position = 0; position < parameters.length; position++) {
        const [value, name, type] = parameters[position];
        const errMessage = validateParameter(formattedMethodName, position, value, name, type);
        if (errMessage !== undefined) error(errMessage, 3);
    }

    /*
    "bad argument '{argName}' #{pos} to '{methodName}' ({type} expected, got {type})"
    "bad argument '{argName}' #{pos} to '{methodName}' ({type} or {type} expected, got {type})"
    "bad argument '{argName}' #{pos} to '{methodName}' ({type}, {type} or {type} expected, got {type})"
    "bad argument '{argName}' #{pos} to '{methodName}' ({type}, {type} or {type} expected, got {type} in {argName}[index])"
    */
}

/**
 * Ensures that a number is within a specific range and floors it optionally.
 */
export function clamp(value: number, min = 0, max = 1, floor = false): number {
    const result = Math.min(Math.max(value, min), max);
    return floor ? Math.floor(result) : result;
}