--The default configuation
--per ,err = P(peripheral,mountedName,configTable)

--Create a new cpu mounted as "CPU"
local CPU, CPUKit = assert(P("CPU"))

--Create a new gpu mounted as "GPU"
local GPU, GPUKit = assert(P("GPU","GPU",{
  --_LIKO_W = 8*48, --384
  --_LIKO_H = 8*32, --256
  _ClearOnRender = true,
  CPUKit = CPUKit
}))

--Create a new keyboard api mounted as "KB"
assert(P("Keyboard","Keyboard",{CPUKit = CPUKit, GPUKit = GPUKit,_Android = (_OS == "Android"),_EXKB = true}))

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
    {KB(20)}, --0x9C00 Compressed Lua Code (20 KB)
    {KB(02)}, --0xCC00 Persistant Data (2 KB)
    {128},    --0xD400 GPIO (128 Bytes)
    {768},    --0xD480 Reserved (768 Bytes)
    {64},     --0xD780 Draw State (64 Bytes)
    {KB(01)}, --0xD7C0 Free Space (1 KB)
    {KB(04)}, --0xDBC0 Reserved (4 KB)
    {KB(12)}, --0xEC00 Label Image (12 KBytes)
    {KB(12)}  --0x11C00 VRAM (12 KBytes)
  }
}

local RAM, RAMKit = assert(P("RAM"),RAMConfig)