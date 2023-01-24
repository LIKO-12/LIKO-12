io.stdout.setvbuf('no');
love.filesystem.setRequirePath(`${love.filesystem.getRequirePath()};?/index.lua`);

import 'core/utf8-adapter';
import 'core/json-adapter';
import 'core/error-handler';
import { options } from 'core/options';

love.conf = (t) => {
    t.identity = 'LIKO-12';
    t.appendidentity = false;
    t.version = '11.3';
    t.console = false;
    t.accelerometerjoystick = false;
    t.externalstorage = true;
    t.gammacorrect = false;

    t.audio.mic = false;
    t.audio.mixwithsystem = true;

    t.window.title = options.window.title;
    t.window.icon = options.window.icon ?? undefined;
    t.window.width = options.window.width;
    t.window.height = options.window.height;
    t.window.borderless = options.window.borderless;
    t.window.resizable = options.window.resizable;
    t.window.minwidth = options.window.minWidth;
    t.window.minheight = options.window.minHeight;
    t.window.fullscreen = options.window.fullscreen;
    t.window.fullscreentype = options.window.fullscreenType as any;
    t.window.vsync = options.window.vsync;
    t.window.msaa = 0;
    t.window.depth = undefined;
    t.window.stencil = undefined;
    t.window.display = 1;
    t.window.highdpi = false;
    t.window.usedpiscale = true;
    t.window.x = options.window.x ?? undefined;
    t.window.y = options.window.y ?? undefined;

    t.modules.audio = false;
    t.modules.data = true;
    t.modules.event = true;
    t.modules.font = true;
    t.modules.graphics = true;
    t.modules.image = true;
    t.modules.joystick = false;
    t.modules.keyboard = true;
    t.modules.math = true;
    t.modules.mouse = true;
    t.modules.physics = false;
    t.modules.sound = true;
    t.modules.system = true;
    t.modules.thread = false;
    t.modules.timer = true;
    t.modules.touch = true;
    t.modules.video = false;
    t.modules.window = true;
}