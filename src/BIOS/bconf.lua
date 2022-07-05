--The bios configuration file.
--per ,err = P(peripheral,mountedName,configTable)

--Ignore unused variables for this file, and set the globals.
--luacheck: globals P PA _OS, ignore 211

--Create a new cpu mounted as "CPU"
local CPU, yCPU, CPUKit = PA("CPU")

--Create a new gpu mounted as "GPU"
local GPU, yGPU, GPUKit = PA("GPU","GPU",{
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
})

local LIKO_W, LIKO_H = GPUKit._LIKO_W, GPUKit._LIKO_H
local ScreenSize = (LIKO_W/2)*LIKO_H

--Create Audio peripheral
PA("Audio")

--Create gamepad contols
PA("Gamepad","Gamepad",{CPUKit = CPUKit})

--Create Touch Controls
PA("TouchControls","TC",{CPUKit = CPUKit, GPUKit = GPUKit})

--Create a new keyboard api mounted as "KB"
PA("Keyboard","Keyboard",{CPUKit = CPUKit, GPUKit = GPUKit,_Android = (_OS == "Android"),_EXKB = false})

--Create a new virtual hdd system mounted as "HDD"
PA("HDD","HDD",{
  Drives = {
    C = 1024*1024 * 50, --Measured in bytes, equals 50 megabytes
    D = 1024*1024 * 50 --Measured in bytes, equals 50 megabytes
  }
})

local KB = function(v) return v*1024 end

local RAMConfig = {
  layout = {
    {ScreenSize,GPUKit.VRAMHandler}, --0x0 -> 0x2FFF - The Video ram
    {ScreenSize,GPUKit.LIMGHandler}, --0x3000 -> 0x5FFF - The Label image
    {KB(64)}  --0x6000 -> 0x15FFF - The floppy RAM
  }
}

local RAM, yRAM, RAMKit = PA("RAM","RAM",RAMConfig)

PA("FDD","FDD",{
  GPUKit = GPUKit,
  RAM = RAM,
  DiskSize = KB(64),
  FRAMAddress = 0x6000
})

local WEB, yWEB, WEBKit = PA("WEB","WEB",{CPUKit = CPUKit})