import { Machine } from 'core/machine';
import { MachineModule } from 'core/machine-module';
import { Queue } from 'core/queue';

export default class Events extends MachineModule {
    private machineListening = false;
    private eventsQueue = new Queue<[eventName: string, ...args: any[]]>();

    constructor(private machine: Machine, options: Record<string, any>) {
        super(machine, options)
    }

    pushEvent(eventName: string, ...args: any[]) {
        this.eventsQueue.push([eventName, ...args]);
        if (this.machineListening) this.machine.resume();
    }

    isMachineListening() {
        return this.machineListening;
    }

    createAPI(_machine: Machine) {
        const eventsAPI = {
            /**
             * Pull an event actively which could suspend the machine until an event is pushed.
             * @returns `eventName: string`.
             * @returns `...args: any[]`.
             */
            pull: () => {
                if (this.eventsQueue.isEmpty()) {
                    this.machineListening = true;
                    coroutine.yield();
                    this.machineListening = false;

                    if (this.eventsQueue.isEmpty())
                        throw 'CRITICAL: the machine was resumed without an event added to the queue';
                }

                return unpack(this.eventsQueue.pop() || []);
            },

            /**
             * Pull an event without suspending the machine if there was none.
             * But instead `undefined` will simply be returned.
             * @returns `eventName: string | undefined`.
             * @returns `...args: any[]`.
             */
            pullPassively: () => {
                return unpack(this.eventsQueue.pop() || []);
            },

            /**
             * Peek into the upcoming event without remove it from the queue.
             * @returns `eventName: string | undefined`.
             * @returns `...args: any[]`.
             */
            peek: () => {
                return unpack(this.eventsQueue.front || [])
            },

            /**
             * Clear the events queue.
             */
            clear: () => {
                this.eventsQueue.clear();
            },

            /**
             * Get the count of the events queued.
             */
            getCount: () => {
                return this.eventsQueue.length;
            },

            /**
             * Check whether there are no events queued or not.
             */
            isEmpty: () => {
                return this.eventsQueue.isEmpty();
            }
        };

        return eventsAPI;
    }
}