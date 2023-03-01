/**
 * Bootstraps the standard LIKO-12 application which runs a single machine.
 */

import { loveEvents } from 'core/love-events';
import { GameRuntimeServer } from 'app/game-runtime-server';

// TODO: Setup eslint for the project.
// TODO: Create eslint rule to warn about missing "validateParameters" call.
// TODO: Create eslint rule for returning a non-proxy object.
// TODO: Create eslint rule for possibly object-exposing actions.
// TODO: Apply the eslint rule to not use default exports (except in MachineModules).
// TODO: Figure out a way to type the events emitter.
// TODO: Figure out a way to document the emitted events.
// TODO: Make sure that the repository satisfies the open-source community standards.

math.randomseed(os.time());

loveEvents.on('load', (args: string[]) => {
    io.write('\x1B[2J\x1B[3J\x1B[1;1H'); // reset the terminal using ANSI escape sequence.

    new GameRuntimeServer({
        debugMode: args.includes('--debug')
    });
});

loveEvents.on('keypressed', (key: string) => {
    if (key !== '\\') return;
    love.event.quit('restart');
});
