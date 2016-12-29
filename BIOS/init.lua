--The BIOS should control the system of LIKO-12 and load the peripherals--
--For now it's just a simple BIOS to get LIKO-12 working.

--Require the engine libraries--
local events = require("Engine.events")
local coreg = require("Engine.coreg")

local function splitFilePath(path) return path:match("(.-)([^\\/]-%.?([^%.\\/]*))$") end --A function to split path to path, name, extension.

local Peripherals = {} --The loaded peripherals.
local MPer = {} --Mounted and initialized peripherals.

--A function to load the peripherals.
local function indexPeripherals(path)
  local files = love.filesystem.getDirectoryItems(path)
  for k,filename in ipairs(files) do
    if love.filesystem.isDirectory(path..filename) then
      indexPeripherals(path..filename.."/")
    else
      local p, n, e = splitFilePath(path..filename)
      if e == "lua" then
        local chunk, err = love.filesystem.load(path..n)
        if not chunk then Peripherals[n:sub(0,-5)] = "Err: "..tostring(err) else
        Peripherals[n:sub(0,-5)] = chunk() end
      end
    end
  end
end

indexPeripherals("/Peripherals/") --Index and Load the peripherals

--Peripheral, Err = P(PeriheralName, MountedName, ConfigTabel)
local function P(per,m,conf)
  if not per then return false, "Should provide peripheral name" end
  if type(per) ~= "string" then return false, "Peripheral name should be a string, provided "..type(per) end
  if not Peripherals[per] then return false, "'"..per.."' Peripheral doesn't exists" end
  if type(Peripherals[per]) == "string" then return false, "Compile "..Peripherals[per] end
  
  local m = m or per
  if type(m) ~= "string" then return false, "Mounting name should be a string, provided "..type(m) end
  if MPer[m] then return false, "Mounting name '"..m.."' is already taken" end
  
  local conf = conf or {}
  if type(conf) ~= "table" then return false, "Configuration table should be a table, provided "..type(conf) end
  
  local success, peripheral = pcall(Peripherals[per],conf)
  if success then
    MPer[m] = peripheral
    coreg:register(peripheral,m)
  else
    peripheral = "Init Err: "..peripheral
  end
  return success, peripheral
end

if not love.filesystem.exists("/bconf.lua") then
  love.filesystem.write("/bconf.lua",love.filesystem.read("/BIOS/bconf.lua"))
end

local bconfC, bconfErr = love.filesystem.load("/bconf.lua")
if not bconfC then bconfC = love.filesystem.load("/BIOS/bconf.lua") end --Load the default BConfig
setfenv(bconfC,{P = P}) --BConfig sandboxing
local success, bconfRErr = pcall(bconfC)
if not success then
  bconfC = love.filesystem.load("/BIOS/bconf.lua")
  setfenv(bconfC,{P = P}) --BConfig sandboxing
  bconfC()
end --Load the default BConfig

--POST screen
--[[if MPer.GPU then --If there is an initialized gpu
  MPer.GPU.color(8)
  for i=1,8 do
    MPer.GPU.print("Hello World")
  end
end]]

--Booting the system !



--[[local GPU = Peripherals.GPU({_ClearOnRender=true}) --Create a new GPU

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
GPU.points(10,10, 10,19, 19,19, 19,10, 8)]]