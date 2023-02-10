import { EnvironmentBox } from '@liko-12/environment-box';
import { pullEvents } from 'lib/utils';

const storage = liko.storage!;
if (!storage) throw 'storage module is not loaded!';

function createGameBox(): EnvironmentBox {
    const box = new EnvironmentBox();

    box.protectEnvironment(_G);
    box.expose({ liko });

    return box;
}

function createEventLoop() {
    return () => {
        for (const [name, a, b, c, d, e, f] of pullEvents()) {
            if (name === 'keypressed' && a === 'escape') break;

            // FIXME: Remove the debugging print.
            if (name !== 'draw' && name !== 'update') print('GAME', name, a, b, c, d, e, f);

            const callbackName = `_${name}`;
            const callback = (_G as any)[callbackName];

            if (typeof callback === 'function') callback(a, b, c, d, e, f);
        }
    };
}

export function runGameScript(gameScript: () => unknown) {
    const eventLoop = createEventLoop();
    createGameBox().apply(gameScript).apply(eventLoop);
    gameScript();
    eventLoop();
}

// export function loadGame() {
//     const scriptFile = storage.open('game.lua', 'r');
//     const scriptContent = scriptFile.read();
//     scriptFile.close();

//     if (scriptContent === undefined) throw 'failed to read script!';

//     const [scriptChunk, err] = loadstring(scriptContent, 'game.lua');
//     if (!scriptChunk) throw err;

//     runGameScript(scriptChunk);
// }
