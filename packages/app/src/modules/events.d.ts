/** @noSelfInFile */
import Machine from "core/machine";
import MachineModule from "core/machine-module";
export default class Events extends MachineModule {
    private machine;
    private machineListening;
    private eventsQueue;
    constructor(machine: Machine, options: Record<string, any>);
    pushEvent(eventName: string, ...args: any[]): void;
    isMachineListening(): boolean;
    createAPI(_machine: Machine): {
        /**
         * Pull an event actively which could suspend the machine until an event is pushed.
         * @returns `eventName: string`.
         * @returns `...args: any[]`.
         */
        pull: () => LuaMultiReturn<never[] | [eventName: string, ...args: any[]]>;
        /**
         * Pull an event without suspending the machine if there was none.
         * But instead `undefined` will simply be returned.
         * @returns `eventName: string | undefined`.
         * @returns `...args: any[]`.
         */
        pullPassively: () => LuaMultiReturn<never[] | [eventName: string, ...args: any[]]>;
        /**
         * Peek into the upcoming event without remove it from the queue.
         * @returns `eventName: string | undefined`.
         * @returns `...args: any[]`.
         */
        peek: () => LuaMultiReturn<never[] | [eventName: string, ...args: any[]]>;
        /**
         * Clear the events queue.
         */
        clear: () => void;
        /**
         * Get the count of the events queued.
         */
        getCount: () => number;
        /**
         * Check whether there are no events queued or not.
         */
        isEmpty: () => boolean;
    };
}
//# sourceMappingURL=events.d.ts.map