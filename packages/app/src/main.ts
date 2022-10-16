import 'bootstrap';
import { loveEvents } from 'core/love-events';

love.run = () => {
    loveEvents.emit('load', love.arg.parseGameArguments(arg), arg);

    // We don't want the first frame's dt to include time taken by love.load.
    love.timer?.step();

    let dt = 0;

    let isQuitConfirmed = true;
    const cancelQuit = () => isQuitConfirmed = false;

    return () => {
        // Process events.
        if (love.event !== undefined) {
            love.event.pump();
            for (const [name, a, b, c, d, e, f] of love.event.poll()) {
                if (name === 'quit') {
                    loveEvents.emit('quit', cancelQuit);
                    if (isQuitConfirmed) return a ?? 0;
                } else {
                    loveEvents.emit(name, a, b, c, d, e, f);
                }
            }
        }

        // Update dt, as we'll be passing it to update
        if (love.timer !== undefined) dt = love.timer.step();

        // Call update and draw
        loveEvents.emit('update', dt); // will pass 0 if love.timer is disabled

        if (love.graphics !== undefined && love.graphics.isActive()) {
            love.graphics.origin();
            const [r, g, b, a] = love.graphics.getBackgroundColor();
            love.graphics.clear(r, g, b, a);

            loveEvents.emit('draw');

            love.graphics.present();
        }

        love.timer?.sleep(0.001);
    };
}