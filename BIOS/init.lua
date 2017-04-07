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
      --indexPeripherals(path..filename.."/")
      if love.filesystem.exists(path..filename.."/init.lua") then
        local chunk, err = love.filesystem.load(path..filename.."/init.lua")
        if not chunk then Peripherals[filename] = "Err: "..tostring(err) else
        Peripherals[filename] = chunk(path..filename.."/") end
      end
    else
      local p, n, e = splitFilePath(path..filename)
      if e == "lua" then
        local chunk, err = love.filesystem.load(path..n)
        if not chunk then Peripherals[n:sub(0,-5)] = "Err: "..tostring(err) else
        Peripherals[n:sub(0,-5)] = chunk(path) end
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
  if MPer[m] then return MPer[m] end--return false, "Mounting name '"..m.."' is already taken" end
  
  local conf = conf or {}
  if type(conf) ~= "table" then return false, "Configuration table should be a table, provided "..type(conf) end
  
  local success, peripheral, devkit = pcall(Peripherals[per],conf)
  if success then
    MPer[m] = peripheral
    coreg:register(peripheral,m)
  else
    peripheral = "Init Err: "..tostring(peripheral)
  end
  return success, peripheral, devkit
end

if not love.filesystem.exists("/bconf.lua") or true then
  love.filesystem.write("/bconf.lua",love.filesystem.read("/BIOS/bconf.lua"))
end

local passert = function(ok, per, devkit) --Peripheral assert
  if not ok then return error(per) end
  return per, devkit
end

local bconfC, bconfErr, bconfDErr = love.filesystem.load("/bconf.lua")
--if not bconfC then bconfC, bconfDErr = love.filesystem.load("/BIOS/bconf.lua") end --Load the default BConfig
if not bconfC then error(bconfDErr) end
setfenv(bconfC,{P = P,error=error,assert=passert}) --BConfig sandboxing
local success, bconfRErr = pcall(bconfC)
if not success then error(bconfRErr)
  bconfC, err = love.filesystem.load("/BIOS/bconf.lua")
  if not bconfC then error(err) end
  setfenv(bconfC,{P = P,error=error,assert=passert}) --BConfig sandboxing
  bconfC()
end --Load the default BConfig

coreg:register(function()
  local list = {}
  for per, funcs in pairs(MPer) do
    list[per] = {}
    for name, func in pairs(funcs) do
      table.insert(list[per],name)
    end
  end
  return true, list
end,"BIOS:listPeripherals")

local function exe(...) --Excute a LIKO12 api function (to handle errors)
  local args = {...}
  if args[1] then
    local nargs = {}
    for k,v in ipairs(args) do --Clone the args, removing the first one
      nargs[k-1] = v
    end
    return unpack(nargs)
  else
    return error(args[2])
  end
end

local function flushOS(os,path)
  local h = MPer.HDD
  local path = path or "/"
  local files = love.filesystem.getDirectoryItems("/OS/"..os..path)
  for k,v in pairs(files) do
    if love.filesystem.isDirectory("/OS/"..os..path..v) then
      exe(h.newDirectory(path..v))
      flushOS(os,path..v.."/")
    else
      exe(h.drive("C")) --Opereating systems are installed on C drive
      exe(h.write(path..v,love.filesystem.read("/OS/"..os..path..v)))
    end
  end
end

--No OS Screen
local function noOS()
  if MPer.GPU then
    flushOS("DiskOS") --Should be replaced by a gui
  else
    flushOS("DiskOS")
  end
end

local function startCoroutine()
  if not MPer.HDD then return error("No HDD Periphrtal") end
  local h = MPer.HDD
  exe(h.drive("C"))
  if (not exe(h.exists("/boot.lua"))) or true then noOS() end
  local chunk, err = exe(h.load("/boot.lua"))
  if not chunk then error(err or "") end
  local coglob = coreg:sandbox(chunk)
  local co = coroutine.create(chunk)
  coreg:setCoroutine(co,coglob) --For peripherals to use.
  if MPer.CPU then MPer.CPU.clearEStack() end
  coreg:resumeCoroutine()
end

--POST screen
if MPer.GPU then --If there is an initialized gpu
  local g = MPer.GPU
  g.color(8)
  local chars = {"@","%","*"}
  --48x16 Terminal Size
  local function drawAnim() g.clear()
    for y=1,exe(g.termHeight())+1 do for x=1,exe(g.termWidth())+1 do
      g.color(8 + (x+y) % 8)
      g.print(chars[((y+x) % 2)+1],false,true)
    end g.printCursor(1,y+1,false) end
  end
  
  g.clear()
  g.printCursor(_,_,0)
  
  local time = 0.3
  local timer = 0
  local stage = 0
  
  events:register("love:update",function(dt)
    if stage == 3 then --Create the coroutine
      g.color(8)
      g.clear(1)
      g.printCursor(1,1,1)
      startCoroutine()
      stage = 4 --So coroutine don't get duplicated
    end
    if stage == 0 then drawAnim() stage = 1 end
    
    if stage < 3 then
      timer = timer + dt
      if timer > time then timer = timer - time
        stage = stage +1
        if stage == 2 then g.clear() end
      end
    end
  end)
else --Incase the gpu doesn't exists (Then can't enter the bios nor do the boot animation
  startCoroutine()
end



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