--BIOS Setup Screen

local Handled, Devkits = ... --It has been passed by the BIOS POST Screen :)

local BIOS = Handled.BIOS
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD

GPU.clear(0)

GPU.color(7)
GPU.printCursor(0,0,0)

GPU.print("Setup")
GPU.print("Press F1 to reflash DiskOS")
GPU.print("Press R to reboot")
while true do
    for event, a, b, c, d, e, f in CPU.pullEvent do
        if event == "keypressed" and a == "f1" and c == false then
           GPU.print("Flashing in 5 seconds...")
           CPU.sleep(5)
           love.filesystem.load("BIOS/installer.lua")(Handled,"DiskOS",false)
           CPU.reboot()
        end
        if event == "keypressed" and a == "r" and c == false then
            CPU.reboot()
        end
    end
end
CPU.reboot()
