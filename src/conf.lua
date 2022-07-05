--==Contribution Guide==--
--[[
This is LOVE configuration file,
It also contains LIKO-12 version table, all other code in LIKO-12 technically references this.

I don't think anyone would want to edit anything in this file, but only change the version number.

==Contributors to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

--LIKO-12 Version
_LVer = {
	major = 1,
	minor = 1,
	patch = 1,
	tag = "Development" --Release, Pre-Relase, Development
}
_LVERSION = string.format("V%d.%d.%d-%s",_LVer.major,_LVer.minor,_LVer.patch,_LVer.tag)

--BuildConfig
local build = {}
if love.filesystem.getInfo and love.filesystem.getInfo("build.json", "file") then
  build = love.filesystem.read("build.json")
  build = require("Engine.JSON"):decode(build)
end

function love.conf(t)
    t.identity = build.Appdata or "LIKO-12"-- The name of the save directory (string)
    t.version = "11.3"                  -- The LÖVE version this game was made for (string)
    t.console = false                   -- Attach a console (boolean, Windows only)
    t.accelerometerjoystick = false     -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
    t.externalstorage = true            -- True to save files (and read from the save directory) in external storage on Android (boolean)
    t.gammacorrect = false              -- Enable gamma-correct rendering, when supported by the system (boolean)

    t.audio.mixwithsystem = true        -- Keep background music playing when opening LOVE (boolean, iOS and Android only)

    t.window = false --The window will be created later by the GPU Peripheral.

    t.modules.audio = true              -- Enable the audio module (boolean)
    t.modules.data = true               -- Enable the data module (boolean)
    t.modules.event = true              -- Enable the event module (boolean)
    t.modules.font = true               -- Enable the font module (boolean)
    t.modules.graphics = true           -- Enable the graphics module (boolean)
    t.modules.image = true              -- Enable the image module (boolean)
    t.modules.joystick = true           -- Enable the joystick module (boolean)
    t.modules.keyboard = true           -- Enable the keyboard module (boolean)
    t.modules.math = true               -- Enable the math module (boolean)
    t.modules.mouse = true              -- Enable the mouse module (boolean)
    t.modules.physics = false           -- Disable the physics module (boolean)
    t.modules.sound = true              -- Enable the sound module (boolean)
    t.modules.system = true             -- Enable the system module (boolean)
    t.modules.thread = true             -- Enable the thread module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = true              -- Enable the touch module (boolean)
    t.modules.video = false             -- Disable the video module (boolean)
    t.modules.window = true             -- Enable the window module (boolean)
end
