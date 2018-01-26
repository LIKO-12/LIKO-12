--BIOS Setup Screen

local Handled, Devkits = ... --It has been passed by the BIOS POST Screen :)

local BIOS = Handled.BIOS
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD

GPU.clear(0)

GPU.color(7)
GPU.printCursor(0,0,0)

GPU.print("COMMING SOON")

CPU.sleep(2)

CPU.reboot()