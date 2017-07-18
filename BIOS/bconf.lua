--The default configuation
--per ,err = P(peripheral,mountedName,configTable)

_DirectAPI = true --An important feature to speed up Peripherals functions calling, calls them directly instead of yeilding the coroutine.

--Create a new cpu mounted as "CPU"
local CPU, CPUKit = assert(P("CPU"))

--Create a new gpu mounted as "GPU"
local GPU, GPUKit = assert(P("GPU","GPU",{
  _ColorSet = { --The P8 Pallete
    {0,0,0,255}, --Black 1
    {28,43,83,255}, --Dark Blue 2
    {127,36,84,255}, --Dark Red 3
    {0,135,81,255}, --Dark Green 4
    {171,82,54,255}, --Brown 5
    {96,88,79,255}, --Dark Gray 6
    {195,195,198,255}, --Gray 7
    {255,241,233,255}, --White 8
    {237,27,81,255}, --Red 9
    {250,162,27,255}, --Orange 10
    {247,236,47,255}, --Yellow 11
    {93,187,77,255}, --Green 12
    {81,166,220,255}, --Blue 13
    {131,118,156,255}, --Purple 14
    {241,118,166,255}, --Pink 15
    {252,204,171,255} --Human Skin 16
  },
  _ClearOnRender = true, --Speeds up rendering, but may cause glitches on some devices !
  CPUKit = CPUKit
}))
local VRAMHandler = GPUKit.VRAMHandler

--Create gamepad contols
assert(P("Gamepad","Gamepad",{CPUKit = CPUKit}))

--Create Touch Controls
assert(P("TouchControls","TC",{CPUKit = CPUKit, GPUKit = GPUKit}))

--Create a new keyboard api mounted as "KB"
assert(P("Keyboard","Keyboard",{CPUKit = CPUKit, GPUKit = GPUKit,_Android = (_OS == "Android"),_EXKB = false}))

--Create a new virtual hdd system mounted as "HDD"
assert(P("HDD","HDD",{
  C = 1024*1024 * 25, --Measured in bytes, equals 25 megabytes
  D = 1024*1024 * 25 --Measured in bytes, equals 25 megabytes
}))

assert(P("Floppy"))

local KB = function(v) return v*1024 end

local RAMConfig = {
  layout = {
    {736},    --0x0000 Meta Data (736 Bytes)
    {KB(12)}, --0x02E0 SpriteMap (12 KB)
    {288},    --0x32E0 Flags Data (288 Bytes)
    {KB(18)}, --0x3400 MapData (18 KB)
    {KB(13)}, --0x7C00 Sound Tracks (13 KB)
    {KB(20)}, --0xB000 Compressed Lua Code (20 KB)
    {KB(02)}, --0x10000 Persistant Data (2 KB)
    {128},    --0x10800 GPIO (128 Bytes)
    {768},    --0x10880 Reserved (768 Bytes)
    {64},     --0x10B80 Draw State (64 Bytes)
    {64},     --0x10BC0 Reserved (64 Bytes)
    {KB(01)}, --0x10C00 Free Space (1 KB)
    {KB(04)}, --0x11000 Reserved (4 KB)
    {KB(12)}, --0x12000 Label Image (12 KBytes)
    {KB(12),VRAMHandler}  --0x15000 VRAM (12 KBytes)
  }
}

local RAM, RAMKit = assert(P("RAM","RAM",RAMConfig))

local _, WEB, WEBKit = P("WEB","WEB",{CPUKit = CPUKit})