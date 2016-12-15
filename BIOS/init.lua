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

local GPU = Peripherals.GPU({}) --Create a new GPU

--Debug Points--
GPU.points(1,1, 192,1, 192,128, 1,128, 8)
GPU.points(0,1, 193,1, 193,128, 0,128, 3)
GPU.points(1,0, 192,0, 192,129, 1,129, 3)