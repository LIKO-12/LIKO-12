type Listener = (...args: any[]) => void;

export default class EventsEmitter {
    public listeners: Record<string, Listener[] | undefined> = {};

    /**
     * Register a callback to be triggered by an event.
     */
    addListener(eventName: string, listener: Listener) {
        const container = this.listeners[eventName] ?? [];
        this.listeners[eventName] = container;

        container.push(listener);

        return this;
    }

    /**
     * Unregister a callback from being triggered by an event.
     * @returns Whether the listener was found and removed or not.
     */
    removeListener(eventName: string, listener: Listener) {
        const container = this.listeners[eventName];
        if (!container) return;

        const index = container.findIndex((entry) => entry === listener);
        if (index === -1) return false;

        const lastIndex = container.length -1;

        for (let i = index + 1; i < lastIndex; i++)
            container[i-1] = container[i];

        delete container[lastIndex];

        return true;
    }

    on = this.addListener;
    off = this.removeListener;

    /**
     * Unregister all listeners, or those of the specified `eventName`.
     * @param eventName 
     */
    removeAllListeners(eventName?: string) {
        if (eventName) delete this.listeners[eventName];
        else this.listeners = {};
    }

    /**
     * Emit an event, calling all the registered listeners with the provided arguments.
     */
    emit(eventName: string, ...args: any[]) {
        this.listeners[eventName]?.forEach((listener) => listener(...args));
    }
}