--The BIOS Post Screen !

local coreg = require("Engine.coreg")

--luacheck: push ignore 211
local Handled, Devkits = ... --It has been passed by the BIOS :)
--luacheck: pop

local BIOS = Handled.BIOS
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD

local _LIKO_Version, _LIKO_Old = BIOS.getVersion()

if _LIKO_Old then
  love.filesystem.write("Miscellaneous/.version",tostring(_LIKO_Version)) --Update the .version file
end

local sw,sh = GPU.screenSize()

local function loadImage(name)
  return GPU.image(love.filesystem.read("/BIOS/Splash/"..name..".lk12"))
end

local function loadImagedata(name)
  return GPU.imagedata(love.filesystem.read("/BIOS/Splash/"..name..".lk12"))
end

--POST Screen--

--ASSETS--
local corner = loadImage("corner")
local likologo = loadImage("likologo")

local Patterns = {}
for i=1,17 do
  Patterns[i] = loadImagedata("p-"..i)
end

local ptimer = 0
local pflag = false

GPU.palt(0,false)
GPU.palt(5,true)

local cx = math.floor((sw-32)/2)
local cy = math.floor((sh-32)/2)

for event,dt,b,c,e,f in CPU.pullEvent do
  if event == "update" then
    ptimer = ptimer + dt*32*(pflag and -1 or 1)
    if ptimer <= 0 and pflag then break end
    if ptimer >= 25 and not pflag then
      pflag = true
    end

    GPU.clear(0)

    GPU.patternFill(Patterns[math.floor(math.min(ptimer,16))+1])

    GPU.rect(0,0,sw,sh,false,5)
    likologo:draw(cx,cy,0,2,2)
    corner:draw(0,0, 0, 1,1)
    corner:draw(sw,0, 0, -1,1)
    corner:draw(sw,sh, 0, -1,-1)
    corner:draw(0,sh, 0, 1,-1)

    GPU.patternFill()
  end
end

GPU.palt()
GPU.color(7) GPU.clear(0)
CPU.sleep(1)

--Boot into GameDiskOS

fs.drive("GameDiskOS") --Switch to the C drive.

CPU.clearEStack() --Remove any events made while booting.

local bootchunk, err = fs.load("/boot.lua")
if not bootchunk then error(err or "") end --Must be replaced with an error screen.

local coglob = coreg.sandbox(bootchunk)
local co = coroutine.create(bootchunk)

local HandledAPIS = BIOS.HandledAPIS()
coroutine.yield("echo",HandledAPIS)
coreg.setCoroutine(co,coglob) --Switch to boot.lua coroutine