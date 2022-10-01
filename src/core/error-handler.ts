import * as utf8 from 'utf8';

function error_printer(msg: string, layer: number) {
    const [formattedMessage] = string.gsub(debug.traceback(`Error: ${msg}`, 1 + (layer ?? 1)), '\n[^\n]+$', '');
    print(formattedMessage);
}

love.errorhandler = (msg: string) => {
    msg = tostring(msg);

    error_printer(msg, 2);

    if (!love.window || !love.graphics || !love.event) return;

    if (!love.window.isOpen()) {
        const [success, status] = pcall(love.window.setMode, 800, 600, {});
        if (!success || !status) return;
    }

    // Reset state.
    love.mouse?.setVisible(true);
    love.mouse?.setGrabbed(false);
    love.mouse?.setRelativeMode(false);
    if (love.mouse?.isCursorSupported()) love.mouse.setCursor();

    if (love.joystick !== undefined)
        // Stop all joystick vibrations.
        for (const joystick of love.joystick.getJoysticks())
            joystick.setVibration();

    love.audio?.stop();

    love.graphics.reset();
    const font = love.graphics.setNewFont(14);

    love.graphics.setColor(1, 1, 1);

    const trace = debug.traceback();

    love.graphics.origin();

    const sanitizedMessageArray = [];
    for (const [char] of string.gmatch(msg, utf8.charpattern))
        sanitizedMessageArray.push(char);
    const sanitizedMessage = sanitizedMessageArray.join('');

    const err = [];

    err.push('Error\n');
    err.push(sanitizedMessage);

    if (sanitizedMessage.length !== msg.length)
        err.push("Invalid UTF-8 string in error message.");

    err.push('\n');

    for (const [l] of string.gmatch(trace, "(.-)\n"))
        if (!string.match(l, "boot.lua"))
            err.push(string.gsub(l, "stack traceback:", "Traceback\n"));

    let p = err.join('\n');

    [p] = string.gsub(p, "\t", "");
    [p] = string.gsub(p, "%[string \"(.-)\"%]", "%1");

    function draw() {
        if (!love.graphics.isActive()) return;

        const pos = 70;
        love.graphics.clear(89 / 255, 157 / 255, 220 / 255);
        love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos);
        love.graphics.present();
    }

    const fullErrorText = p;
    p = p + '\n\nPress \\ to restart';

    function copyToClipboard() {
        if (!love.system) return;
        love.system.setClipboardText(fullErrorText);
        p = p + "\nCopied to clipboard!";
    }

    if (love.system !== undefined)
        p = p + "\nPress Ctrl+C or tap to copy this error";

    return () => {
        love.event.pump();

        for (const [event, key] of love.event.poll()) {
            if (event === "quit") return 1;
            else if (event === "keypressed" && key === "escape") return 1;
            else if (event === "keypressed" && key === "\\") return 'restart';
            else if (event === "keypressed" && key === "c" && love.keyboard.isDown("lctrl", "rctrl")) copyToClipboard();
            else if (event === "touchpressed") {
                let name = love.window.getTitle();
                if (name === '' || name === 'Untitled') name = "Game";

                const buttons = ["OK", "Cancel"];
                if (love.system !== undefined) buttons[3] = 'Copy to clipboard';

                const pressed = love.window.showMessageBox(`Quit ${name}?`, '', buttons);
                if (pressed === 1) return 1;
                else if (pressed === 3) copyToClipboard();
            }
        }

        draw();

        love.timer?.sleep(0.1);
    }
}

error('TEST MAN');