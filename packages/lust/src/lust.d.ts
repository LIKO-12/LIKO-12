// Type definitions for lust.lua 538de7c
// Project: LIKO-12
// Definitions by: Rami Sabbagh <https://github.com/Rami-Sabbagh/>

/** @noSelfInFile */

// TODO: Publish this package independently so other tstl users can benefit from it.
// TODO: Port README.md to TS.

type Func = (...args: any[]) => any;

interface Lust {
    /**
     * Disable ANSI color escape sequences.
     * Useful when not running in a console environment that understands ANSI color escapes.
     */
    nocolor(): Lust;

    /**
     * Declare a group of tests, nested groups are allowed.
     * 
     * @param name group description.
     * @param func a function containing all tests and `describe` blocks in the group.
     */
    describe(name: string, func: Func): void;

    /**
     * Declare a test.
     * 
     * @param name test description.
     * @param func a function containing the assertions.
     */
    it(name: string, func: Func): void;

    /**
     * Define a function that is called before every call to `lust.it`.
     * Scoped to the `describe` block containing it.
     */
    before(func: Func): void;

    /**
     * Define a function that is called after every call to `lust.it`.
     * Scoped to the `describe` block containing it.
     */
    after(func: Func): void;

    /**
     * Assertion.
     */
    expect(x: unknown): LustExpect;

    /**
     * Spies on a function and tracks the number of times it was called and the arguments it was called with.
     * @param func The target function.
     * @param run a function that will be called immediately upon creation of the spy.
     */
    spy<T extends Func = Func>(func: T | undefined, run: Func): LustSpy<T>;

    /**
     * Spies on a function and tracks the number of times it was called and the arguments it was called with.
     * @param obj an object containing functions.
     * @param name the name of the function in the object.
     * @param run a function that will be called immediately upon creation of the spy.
     */
    spy<O extends Record<string, Func>, N extends keyof O>(obj: O, name: N, run: Func): LustSpy<O[N]>;

    /**
     * Spies on a function and tracks the number of times it was called and the arguments it was called with.
     * @param obj an object containing functions.
     * @param name the name of the function in the object.
     * @param run a function that will be called immediately upon creation of the spy.
     */
    spy(obj: Object, name: string, run: Func): LustSpy<Func>;

    // TODO: Custom Assertions
}

/**
 * An array that will contain one element for each call to the function.
 * Each element is a table containing the arguments passed to that particular invocation of the function.
 * The array can also be called as a function, in which case it will call the function it is spying on.
 */
type LustSpy<F extends Func> = F & [parameters: Parameters<F>, returns: [...ReturnType<F>]][];

interface LustExpect {
    to: LustExpectTo;

    /**
     * Negate the assertion.
     */
    to_not: LustExpectTo;
}

interface LustExpectTo {
    /**
     * Fails if `x` is `undefined`.
     */
    exist(): void;

    /**
     * Performs a strict equality test, failing if x and y have different types or values.
     * Objects are tested by recursively ensuring that both tables contain the same set of keys and values.
     * 
     * Metatables are not taken into consideration.
     */
    equal(y: unknown): void;

    be: LustExpectToBeMethod & LustExpectToBe;

    /**
     * If `x` is an object, ensures that at least one of its keys
     * contains the value `y` using the `==` operator.
     * 
     * If `x` is not an object, this assertion fails.
     */
    have(y: unknown): void;

    /**
     * Ensures that the function `x` causes an error when it's run.
     */
    fail(): void;

    /**
     * Fails if the string representation of `x` does not match the pattern `p`.
     * @param p a Lua regex pattern.
     */
    match(p: string): void;
}

/**
 * Performs an equality test using the `==` operator. Fails if `x != y`.
 */
type LustExpectToBeMethod = (y: unknown) => void;

interface LustExpectToBe {
    /**
     * Fails if `x` is `undefined` or `false`.
     */
    truthy(): void;

    /**
     * Fails if `type(x)` is not equal to `y`.
     */
    a(y: ReturnType<typeof type>): void;

    /**
     * Walks up `x`'s metatable chain and fails if `y` is not encountered.
     */
    a(y: Object): void;
}

declare const lust: Lust;
export = lust;