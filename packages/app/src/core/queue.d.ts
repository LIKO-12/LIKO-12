/** @noSelfInFile */
/**
 * Simple implementation of a linked FIFO queue
 * that doesn't throw any errors/exceptions.
 */
export default class Queue<T> {
    private _length;
    private _head?;
    private _tail?;
    isEmpty(): boolean;
    get length(): number;
    push(value: T): this;
    pop(): T | undefined;
    /**
     * Access the first value in the queue without removing it.
     */
    get front(): T | undefined;
    /**
     * Access the last value in the queue without removing it.
     */
    get back(): T | undefined;
    clear(): this;
}
//# sourceMappingURL=queue.d.ts.map