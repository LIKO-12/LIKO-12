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
  if MPer[m] then return MPer[m] end--return false, "Mounting name '"..m.."' is already taken" end
  
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

if not love.filesystem.exists("/bconf.lua") or true then
  love.filesystem.write("/bconf.lua",love.filesystem.read("/BIOS/bconf.lua"))
end

local bconfC, bconfErr, bconfDErr = love.filesystem.load("/bconf.lua")
if not bconfC then bconfC, bconfDErr = love.filesystem.load("/BIOS/bconf.lua") end --Load the default BConfig
if not bconfC then error(bconfDErr) end
setfenv(bconfC,{P = P,error=error,assert=assert}) --BConfig sandboxing
local success, bconfRErr = pcall(bconfC)
if not success then
  bconfC, err = love.filesystem.load("/BIOS/bconf.lua")
  if not bconfC then error(err) end
  setfenv(bconfC,{P = P,error=error,assert=assert}) --BConfig sandboxing
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
    flushOS("CartOS") --Should be replaced by a gui
  else
    flushOS("CartOS")
  end
end

local function startCoroutine()
  if not MPer.HDD then return error("No HDD Periphrtal") end
  local h = MPer.HDD
  exe(h.drive("C"))
  if (not exe(h.exists("/boot.lua"))) or true then noOS() end
  local chunk, err = exe(h.load("/boot.lua"))
  if not chunk then error(err or "") end
  coreg:sandboxCoroutine(chunk)
  local co = coroutine.create(chunk)
  coreg:setCoroutine(co) --For peripherals to use.
  coreg:resumeCoroutine()
end

--POST screen
if MPer.GPU then --If there is an initialized gpu
  local g = MPer.GPU
  g.color(8)
  local chars = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","-","_","@","#","$","&","*","!","+","=","%"}
  --48x16 Terminal Size
  function drawAnim() g.clear()
    for x=1,exe(g.termwidth()) do for y=1,exe(g.termheight()) do
      math.randomseed(os.clock()*os.time()*x)
      g.color(math.floor(math.random(2,16)))
      g.printCursor(x,y)
      math.randomseed(os.clock()*os.time()*y)
      local c = chars[math.floor(math.random(1,#chars))]
      if math.random(0,20) % 2 == 0 then c = c:upper() end
      g.print(c)
    end end
  end
  
  g.clear()
  
  local timer = 0
  local stage = 1
  
  events:register("love:update",function(dt)
    if stage == 7 then --Create the coroutine
      g.color(8)
      g.clear(1)
      g.printCursor(1,1)
      startCoroutine()
      stage = 8 --So coroutine don't get duplicated
    end
    if stage < 4 and stage > 1 then drawAnim() end
    
    if stage < 8 then
      timer = timer + dt
      if timer > 0.25 then timer = timer -0.25
        stage = stage +1
        if stage < 5 then --[[drawAnim()]] elseif stage == 5 then g.clear() end
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