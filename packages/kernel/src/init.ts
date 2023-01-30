import 'tests/storage.test';
import 'tests/font.test';

import 'proto/image-file.test';

import 'proto/game';

function pullEvents(): LuaIterable<LuaMultiReturn<[string, ...any]>> {
    const { events } = liko;
    if (!events) throw 'events module is not loaded!';

    return (() => events.pull()) as any;
}

for (const [event, a, b, c, d, e, f] of pullEvents()) {
    if (event !== 'draw' && event !== 'update')
        print(event, a, b, c, d, e, f);
}

