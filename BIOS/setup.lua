--BIOS Setup Screen

local Handled = ... --Handled is passed by BIOS POST, love is available too.

local BIOS = Handled.BIOS
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD
local KB = Handled.Keyboard
local coreg = require("Engine.coreg")
local stopWhile = false
local wipingMode = false
GPU.clear(0)

GPU.color(7)
KB.textinput(true)
local function drawInfo()
  GPU.clear(0)
  GPU.printCursor(0,0,0)
  GPU.print("LIKO-12 Setup ------ Press R to reboot")
  GPU.print("Press O to reflash DiskOS")
  GPU.print("Press B to boot from D:")
  GPU.print("Press W then C or D to wipe a disk")
end
local function attemptBootFromD()
  fs.drive("D")
  local bootchunk, err = fs.load("/boot.lua")
  if not bootchunk then error(err or "") end
  local coglob = coreg:sandbox(bootchunk)
  local co = coroutine.create(bootchunk)

  local HandledAPIS = BIOS.HandledAPIS()

  coroutine.yield("echo",HandledAPIS)
  coreg:setCoroutine(co,coglob) --Switch to boot.lua coroutine
end
drawInfo()
while not stopWhile do
  for event, a, _, c, _, _, _ in CPU.pullEvent do
    if event == "keypressed" and c == false then
      if a == "o" then
        GPU.print("Flashing in 5 seconds...")
        CPU.sleep(5)
        love.filesystem.load("BIOS/installer.lua")(Handled,"DiskOS",false)
        CPU.reboot()
      end
      if a == "r" then
        CPU.reboot()
      end
      if a == "w" then
        wipingMode = true
        GPU.print("Wiping mode enabled")
        GPU.flip()
      end
      if a == "b" then
        if not fs.exists("/boot.lua") then
          GPU.print("Could not find boot.lua")
          CPU.sleep(1)
          drawInfo()
        else
          stopWhile = true
          break
        end
      end
      if wipingMode then
        if a == "c" then
          GPU.print("Wiping C: in 15 seconds!")
          CPU.sleep(15)
          GPU.print("Please wait, wiping...")
          fs.drive("C")
          fs.delete("/")
          GPU.print("Wipe done.")
          GPU.flip()
          CPU.sleep(1)
          drawInfo()
        end
        if a == "d" and c == false then
          GPU.print("Wiping D: in 15 seconds!")
          CPU.sleep(15)
          GPU.print("Please wait, wiping...")
          fs.drive("D")
          fs.delete("/")
          GPU.print("Wipe done.")
          CPU.sleep(1)
          drawInfo()
        end
      end
    end
    if event == "touchpressed" then
      KB.textinput(true)
    end
  end
end
attemptBootFromD()