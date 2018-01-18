--The BIOS Post Screen !

local DevMode = love.filesystem.exists("/devmode.txt")

local events = require("Engine.events")
local coreg = require("Engine.coreg")

local Handled, Devkits = ... --It has been passed by the BIOS :)

local BIOS = Handled.BIOS
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD

local RAMKit = Devkits.RAM

local _LIKO_Version, _LIKO_Old = BIOS.getVersion()

--POST Screen--
GPU.clear() --Fill with black.
GPU.color(7) --Set the color to white.

--Load the bios logos.
local lualogo = GPU.image(love.filesystem.read("/BIOS/lualogo.lk12"))
local likologo = GPU.image(love.filesystem.read("/BIOS/likologo.lk12"))

local sw,sh = GPU.screenSize()

GPU.flip()
CPU.sleep(0.5)

lualogo:draw(sw-lualogo:width()-6,5)
likologo:draw(2,7)

GPU.print("LIKO-12 - Fantasy Computer",15,6)
GPU.print("Copyright (C) Rami Sabbagh",15,13)
GPU.printCursor(0,3,0)
GPU.print("NormBIOS Revision 060-013")
if DevMode then GPU.color(6) GPU.print("# Devmode Enabled #") GPU.color(7) end
GPU.print("")

GPU.print("Press DEL to enter setup",2,sh-7)

GPU.flip()
CPU.sleep(0.3)

GPU.print("Main CPU: LuaJIT 5.1")
if ram then GPU.print("RAM: "..(ramkit.ramsize/1024).." Kilo-Bytes ("..ramkit.ramsize.." Bytes)") end
GPU.print("GPU: "..sw.."x"..sh.." 4-Bit (16 Color Palette)")
GPU.print("")
GPU.print("Harddisks: ")

GPU.flip()
CPU.sleep(0.3)

Devkits["HDD"].calcUsage()
for letter,drive in pairs(fs.drives()) do
  local size = math.floor((drive.size/1024) * 100)/100
  local usage = math.floor((drive.usage/1024) * 100)/100
  local percentage = math.floor(((usage*100)/size) * 100)/100
  GPU.print("Drive "..letter..": "..usage.."/"..size.." KB ("..percentage.."%)")
end

GPU.flip()
CPU.sleep(1.5)

GPU.clear()
GPU.printCursor(0,0,0)

GPU.flip()
CPU.sleep(0.2)

fs.drive("C") --Switch to the C drive.

local function InstallOS(update)
  love.filesystem.load("BIOS/installer.lua")(Handled,"DiskOS",update)
end

if not fs.exists("/boot.lua") then _LIKO_Old = false; InstallOS()
elseif DevMode then _LIKO_Old = false; InstallOS(true) end

--Update the operating system
if _LIKO_Old then
  InstallOS(true)
  love.filesystem.write(".version",tostring(_LIKO_Version)) --Update the .version file
end

if DevMode and love.thread then
  local FThread = love.thread.newThread("/BIOS/filethread.lua") --File tracking thread
  FThread:start()
  
  events:register("love:reboot",function()
		local channel = love.thread.getChannel("BIOSFileThread")
		channel:push(true) --Shutdown the thread
	end)

  events:register("love:quit",function()
		local channel = love.thread.getChannel("BIOSFileThread")
		channel:push(true) --Shutdown the thread
		FThread:wait()
	end)
end

local bootchunk, err = fs.load("/boot.lua")
if not bootchunk then error(err or "") end --Must be replaced with an error screen.

local coglob = coreg:sandbox(bootchunk)
local co = coroutine.create(bootchunk)

CPU.clearEStack() --Remove any events made while booting.
local HandledAPIS = BIOS.HandledAPIS()

coroutine.yield("echo",HandledAPIS)

coreg:setCoroutine(co,coglob) --Switch to boot.lua coroutine