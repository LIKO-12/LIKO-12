// import 'tests/storage.test';
// import 'tests/font.test';

// import 'proto/image-file.test';

// import 'proto/remote';

import { pullEvents } from 'lib/utils';

_eventLoop = () => {
    for (const [name, a, b, c, d, e, f] of pullEvents()) {
        if (name === 'keypressed' && a === 'escape') break;

        // FIXME: Remove the debugging print.
        if (name !== 'draw' && name !== 'update') print('GAME', name, a, b, c, d, e, f);

        const callbackName = `_${name}`;
        const callback = (_G as any)[callbackName];

        if (typeof callback === 'function') callback(a, b, c, d, e, f);
    }
}