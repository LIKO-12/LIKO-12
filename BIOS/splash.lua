--The BIOS Post Screen !

local Config = love.filesystem.read("build.json")

local json = require("Engine.JSON")

Config = json:decode(Config)

local events = require("Engine.events")
local coreg = require("Engine.coreg")

local Handled, Devkits = ... --It has been passed by the BIOS :)

local BIOS = Handled.BIOS
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD

local RAMKit = Devkits.RAM

local _LIKO_Version, _LIKO_Old = BIOS.getVersion()

if _LIKO_Old then
  love.filesystem.write(".version",tostring(_LIKO_Version)) --Update the .version file
end

local Mobile = CPU.isMobile()

local sw,sh = GPU.screenSize()

local enterSetup = false --Delete/Escape has been pressed, enter setup.

local function wait(timeout) --Wait for 'delete' or 'escape' keypress.
  local timer = timeout
  local setupkey = Mobile and "escape" or "delete"
  for event, a,b,c,d,e,f in CPU.pullEvent do
    if event == "update" then
      timer = timer - a
      if timer <= 0 then return end
    elseif event == "keypressed" then
      if a == setupkey then
        enterSetup = true
        
        GPU.rect(0,sh-8,sw,8,false, 7) GPU.color(0)
        GPU.print("Entering Setup...       ",2,sh-7) GPU.color(7)
        GPU.flip()
      end
    end
  end
end

--POST Screen--
GPU.clear() --Fill with black.
GPU.color(7) --Set the color to white.

--Load the bios logos.
local lualogo = GPU.image(love.filesystem.read("/BIOS/lualogo.lk12"))
local likologo = GPU.image(love.filesystem.read("/BIOS/likologo.lk12"))

GPU.flip()
wait(0.5)

lualogo:draw(sw-lualogo:width()-6,5)
likologo:draw(2,7)

GPU.print("LIKO-12 - Fantasy Computer",15,6)
GPU.print("Copyright (C) Rami Sabbagh",15,13)
GPU.printCursor(0,3,0)
GPU.print(string.format("NormBIOS Revision %d%d%d-015",_LVer.magor,_LVer.minor,_LVer.patch))
if DevMode then GPU.color(6) GPU.print("# Devmode Enabled #") GPU.color(7) end
GPU.print("")

GPU.flip()
wait(0.3)

if CPU.isMobile() then
  GPU.print("Main CPU: Lua 5.1")
else
  GPU.print("Main CPU: LuaJIT 5.1")
end

if ram then GPU.print("RAM: "..(ramkit.ramsize/1024).." Kilo-Bytes ("..ramkit.ramsize.." Bytes)") end
GPU.print("GPU: "..sw.."x"..sh.." 4-Bit (16 Color Palette)")
GPU.print("")
GPU.print("Harddisks: ")

GPU.flip()
wait(0.3)

Devkits["HDD"].calcUsage()
for letter,drive in pairs(fs.drives()) do
  local size = math.floor((drive.size/1024) * 100)/100
  local usage = math.floor((drive.usage/1024) * 100)/100
  local percentage = math.floor(((usage*100)/size) * 100)/100
  GPU.print("Drive "..letter..": "..usage.."/"..size.." KB ("..percentage.."%)")
end

GPU.flip()
wait(1.5)

GPU.clear()
GPU.printCursor(0,0,0)

GPU.flip()
wait(0.2)

fs.drive("GameDiskOS") --Switch to the C drive.

CPU.clearEStack() --Remove any events made while booting.
  
local bootchunk, err = fs.load("/boot.lua")
if not bootchunk then error(err or "") end --Must be replaced with an error screen.

local coglob = coreg:sandbox(bootchunk)
local co = coroutine.create(bootchunk)

local HandledAPIS = BIOS.HandledAPIS()
coroutine.yield("echo",HandledAPIS)
coreg:setCoroutine(co,coglob) --Switch to boot.lua coroutine