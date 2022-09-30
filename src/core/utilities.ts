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