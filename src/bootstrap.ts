/**
 * Bootstraps the standard LIKO-12 application which runs a single machine.
 */

import loveEvents from "core/love-events";

loveEvents.on('load', () => {
    print('Hello from TypeScript');
    love.graphics.setBackgroundColor(.5, 0, .5);
});

loveEvents.on('draw', () => {
    love.graphics.setColor(1, 1, 1, 1);
    love.graphics.print('Hello from TypeScript!', 20, 20);
});