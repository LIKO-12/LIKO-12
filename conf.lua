--Nothing should be changed with this config expect: window size, enabling a module.
_LVERSION = "V0.6.0_DEV_08"
_LVer = {
	magor = 0,
	minor = 6,
	patch = 0,
	build = "8_DEV", --"8_DEV"
}
function love.conf(t)
    t.identity = "liko12"               -- The name of the save directory (string)
    t.version = "0.10.2"                -- The LÖVE version this game was made for (string)
    t.console = false                   -- Attach a console (boolean, Windows only)
    t.accelerometerjoystick = false     -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
    t.externalstorage = true            -- True to save files (and read from the save directory) in external storage on Android (boolean) 
    t.gammacorrect = false              -- Enable gamma-correct rendering, when supported by the system (boolean)
    
    t.window = false --The window will be created later by the GPU Peripheral.
 
    t.modules.audio = false             -- Disable the audio module (boolean)
    t.modules.event = true              -- Enable the event module (boolean)
    t.modules.graphics = true           -- Enable the graphics module (boolean)
    t.modules.image = true              -- Enable the image module (boolean)
    t.modules.joystick = true           -- Enable the joystick module (boolean)
    t.modules.keyboard = true           -- Enable the keyboard module (boolean)
    t.modules.math = true               -- Enable the math module (boolean)
    t.modules.mouse = true              -- Enable the mouse module (boolean)
    t.modules.physics = false           -- Disable the physics module (boolean)
    t.modules.sound = false             -- Disable the sound module (boolean)
    t.modules.system = true             -- Enable the system module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = true              -- Enable the touch module (boolean)
    t.modules.video = false             -- Disable the video module (boolean)
    t.modules.window = true             -- Enable the window module (boolean)
    t.modules.thread = true             -- Enable the thread module (boolean)
end