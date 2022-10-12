interface Node<T> {
    value: T;
    next?: Node<T>;
}

/**
 * Simple implementation of a linked FIFO queue
 * that doesn't throw any errors/exceptions.
 */
export default class Queue<T> {
    private _length = 0;

    private _head?: Node<T>;
    private _tail?: Node<T>;

    isEmpty() {
        return this._length === 0;
    }

    get length() {
        return this._length;
    }

    push(value: T) {
        const node: Node<T> = { value, next: undefined };

        if (this._head === undefined) this._head = node;
        if (this._tail !== undefined) this._tail.next = node;

        this._tail = node;
        this._length++;

        return this;
    }

    pop() {
        const node = this._head;
        if (!node) return;

        this._head = node.next;
        this._length--;

        if (this._length === 0) this._tail = undefined;

        return node.value;
    }

    /**
     * Access the first value in the queue without removing it.
     */
    get front() {
        return this._head?.value;
    }

    /**
     * Access the last value in the queue without removing it.
     */
    get back() {
        return this._tail?.value;
    }

    clear() {
        this._length = 0;
        this._head = undefined;
        this._tail = undefined;

        return this;
    }
}
