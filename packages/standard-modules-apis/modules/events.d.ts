/// <reference types='@typescript-to-lua/language-extensions'/>

declare module "@liko-12/standard-modules-apis" {
    export interface EventsAPI {
        /**
         * Pull an event actively which could suspend the machine until an event is pushed.
         * @returns `eventName: string`.
         * @returns `...args: any[]`.
         */
        pull(this: void): LuaMultiReturn<[eventName: string, ...args: any[]]>;

        /**
         * Pull an event without suspending the machine if there was none.
         * But instead `undefined` will simply be returned.
         * @returns `eventName: string | undefined`.
         * @returns `...args: any[]`.
         */
        pullPassively(this: void): LuaMultiReturn<[eventName: string, ...args: any[]] | never[]>;

        /**
         * Peek into the upcoming event without remove it from the queue.
         * @returns `eventName: string | undefined`.
         * @returns `...args: any[]`.
         */
        peek(this: void): LuaMultiReturn<[eventName: string, ...args: any[]] | never[]>;

        /**
         * Clear the events queue.
         */
        clear(this: void): void;

        /**
         * Get the count of the events queued.
         */
        getCount(this: void): number;

        /**
         * Check whether there are no events queued or not.
         */
        isEmpty(this: void): boolean;
    }
}