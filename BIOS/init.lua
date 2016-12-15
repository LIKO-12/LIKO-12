--The BIOS should control the system of LIKO-12 and load the peripherals--
--For now it's just a simple BIOS to get LIKO-12 working.

--Require the engine libraries--
local events = require("Engine.events")
local coreg = require("Engine.coreg")

local function splitFilePath(path) return path:match("(.-)([^\\/]-%.?([^%.\\/]*))$") end --A function to split path to path, name, extension.

local Peripherals = {} --The loaded peripherals.

--A function to load the peripherals.
local function indexPeripherals(path)
  local files = love.filesystem.getDirectoryItems(path)
  for k,filename in ipairs(files) do
    if love.filesystem.isDirectory(path..filename) then
      indexPeripherals(path..filename.."/")
    else
      local p, n, e = splitFilePath(path..filename)
      if e == "lua" then
        local chunk, err = love.filesystem.load(path..n) if not chunk then error(err) end
        Peripherals[n:sub(0,-5)] = chunk()
      end
    end
  end
end

indexPeripherals("/Peripherals/") --Index and Load the peripherals

local GPU = Peripherals.GPU({_ClearOnRender=true}) --Create a new GPU

--FPS display
events:register("love:update",function(dt) love.window.setTitle("LIKO-12 FPS: "..love.timer.getFPS()) end)

--Debug Draw--
GPU.points(1,1, 192,1, 192,128, 1,128, 8)
GPU.points(0,1, 193,1, 193,128, 0,128, 3)
GPU.points(1,0, 192,0, 192,129, 1,129, 3)
GPU.rect(2,2, 190,126, true, 12)
GPU.line(2,2,191,2,191,127,2,127,2,2,12)
GPU.line(2,2, 191,127, 9)
GPU.line(191, 2,2,127, 9)
GPU.rect(10,42,10,10,false,9)
GPU.rect(10,30,10,10,false,9)
GPU.rect(10,30,10,10,true,8)
GPU.points(10,10, 10,19, 19,19, 19,10, 8)