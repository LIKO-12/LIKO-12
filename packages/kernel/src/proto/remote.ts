import { pullEvents } from 'lib/utils';
import { runGameScript } from './game';

function loadScript(data: string): () => unknown {
    const [script, err] = loadstring(data, 'game.lua');
    if (!script) throw err;
    return script;
}

for (const [event, a, b, c, d, e, f] of pullEvents()) {
    if (event === 'run') {
        print('Loading the received script...');
        const script = loadScript(a);
        print('Executing the received script...');
        runGameScript(script);
        print('Resuming listening to the server...');
        continue;
    }

    if (event !== 'draw' && event !== 'update')
        print(event, a, b, c, d, e, f);
}