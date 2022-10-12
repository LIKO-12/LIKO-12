/** @noSelfInFile */
declare type Listener = (...args: any[]) => void;
export default class EventsEmitter {
    listeners: Record<string, Listener[] | undefined>;
    /**
     * Register a callback to be triggered by an event.
     */
    addListener(eventName: string, listener: Listener): this;
    /**
     * Unregister a callback from being triggered by an event.
     * @returns Whether the listener was found and removed or not.
     */
    removeListener(eventName: string, listener: Listener): boolean | undefined;
    on: (eventName: string, listener: Listener) => this;
    off: (eventName: string, listener: Listener) => boolean | undefined;
    /**
     * Unregister all listeners, or those of the specified `eventName`.
     * @param eventName
     */
    removeAllListeners(eventName?: string): void;
    /**
     * Emit an event, calling all the registered listeners with the provided arguments.
     */
    emit(eventName: string, ...args: any[]): void;
}
export {};
//# sourceMappingURL=events-emitter.d.ts.map