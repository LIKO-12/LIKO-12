import { loveEvents } from 'core/love-events';
import { Machine } from 'core/machine';
import { MachineModule } from 'core/machine-module';

import Events from 'modules/events';

export default class Timer extends MachineModule {
    constructor(machine: Machine, options: {}) {
        super(machine, options);

        const events = machine.resolveModule<Events>('events')!;

        // TODO: Document the events.

        loveEvents.on('update', (dt: number) => {
            events.pushEvent('update', dt);
        });
    }
}