/**
 * Bootstraps the standard LIKO-12 application which runs a single machine.
 */

import { options } from 'core/options';
import { loveEvents } from 'core/love-events';
import { Machine } from 'core/machine';
import Events from 'modules/events';

// TODO: Setup eslint for the project.
// TODO: Create eslint rule to warn about missing "validateParameters" call.
// TODO: Create eslint rule for returning a non-proxy object.
// TODO: Create eslint rule for possibly object-exposing actions.
// TODO: Apply the eslint rule to not use default exports (except in MachineModules).
// TODO: Figure out a way to type the events emitter.
// TODO: Figure out a way to document the emitted events.
// TODO: Make sure that the repository satisfies the open-source community standards.

math.randomseed(os.time());

const [rawProgram] = love.filesystem.read('res/init.lua');

loveEvents.on('load', () => {
    const machine = new Machine(options.modules, options.options);
    const events = machine.resolveModule<Events>('events');
    if (!events) throw 'WHERE EVENTS';

    const [program, compileError] = loadstring(rawProgram ?? '', 'program');
    if (!program) throw compileError;

    machine.load(program);
    events.pushEvent('ping', 1);
    events.pushEvent('ping', 2);
    machine.resume();

    print('yielded', 'dead:', machine.isDead());
    events.pushEvent('ping', 3);
    print('-p1');
    events.pushEvent('ping', 4);
    print('-p2');
    events.pushEvent('ping', 5);
    print('done');
});

loveEvents.on('keypressed', (key: string) => {
    if (key !== '\\') return;
    love.event.quit('restart');
});
