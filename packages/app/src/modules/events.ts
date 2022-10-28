import { EventsAPI } from '@liko-12/standard-modules-types';

import { Machine } from "core/machine";
import { MachineModule } from "core/machine-module";
import { Queue } from "core/queue";

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

    createAPI(_machine: Machine): EventsAPI {
        return {
            pull: () => {
                if (this.eventsQueue.isEmpty()) {
                    this.machineListening = true;
                    coroutine.yield();
                    this.machineListening = false;

                    if (this.eventsQueue.isEmpty())
                        throw 'CRITICAL: the machine was resumed without an event added to the queue';
                }

                return unpack(this.eventsQueue.pop() ?? error('CRITICAL: invalid state'));
            },

            pullPassively: () => {
                return unpack(this.eventsQueue.pop() || []);
            },

            peek: () => {
                return unpack(this.eventsQueue.front || [])
            },

            clear: () => {
                this.eventsQueue.clear();
            },

            getCount: () => {
                return this.eventsQueue.length;
            },

            isEmpty: () => {
                return this.eventsQueue.isEmpty();
            }
        };
    }
}