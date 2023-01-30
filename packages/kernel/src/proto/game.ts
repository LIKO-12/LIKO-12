import { EnvironmentBox } from '@liko-12/environment-box';

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
        const events = liko.events!;
        if (!events) throw 'events module is not loaded!';

        const screen = liko.screen!;
        if (!screen) throw 'screen module is not loaded!';

        while (true) {
            let [name, a, b, c, d, e, f] = events.pull();
            if (name === 'keypressed' && a === 'escape') break;

            // FIXME: Remove the debugging print.
            if (name !== 'draw' && name !== 'update') print('GAME', name, a, b, c, d, e, f);

            const callbackName = `_${name}`;
            const callback = (_G as any)[callbackName];

            if (typeof callback === 'function') callback(a, b, c, d, e, f);
        }
    };
}

function loadGame() {
    const scriptFile = storage.open('game.lua', 'r');
    const scriptContent = scriptFile.read();
    scriptFile.close();

    if (scriptContent === undefined) throw 'failed to read script!';

    const [scriptChunk, err] = loadstring(scriptContent, 'game.lua');
    if (!scriptChunk) throw err;

    const eventLoop = createEventLoop();

    createGameBox().apply(scriptChunk).apply(eventLoop);

    scriptChunk();
    eventLoop();
}

loadGame();
