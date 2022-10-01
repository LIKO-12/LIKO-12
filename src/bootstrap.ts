/**
 * Bootstraps the standard LIKO-12 application which runs a single machine.
 */

import options from 'core/options';
import loveEvents from 'core/love-events';
import Machine from 'core/machine';
import Events from 'modules/events';

const rawProgram = `
print('hello from Lua');

graphics.rectangle(1.5, 1.5, 3, 3);

print(coroutine.running());

for eventName, a,b,c,d,e,f in events.pull do
    print(eventName, a,b,c,d,e,f);
end
`;

loveEvents.on('load', () => {
    const machine = new Machine(options.modules, options.options);
    const events = machine.resolveModule<Events>('events');
    if (!events) throw 'WHERE EVENTS';

    const [program, compileError] = loadstring(rawProgram, 'program');
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
