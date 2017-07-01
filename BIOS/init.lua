--The BIOS should control the system of LIKO-12 and load the peripherals--
--For now it's just a simple BIOS to get LIKO-12 working.

local _LIKO_Version = _LVer.magor..".".._LVer.minor..".".._LVer.patch..".".._LVer.build
love.filesystem.write(".version",tostring(_LIKO_Version))

--Require the engine libraries--
local events = require("Engine.events")
local coreg = require("Engine.coreg")

local function splitFilePath(path) return path:match("(.-)([^\\/]-%.?([^%.\\/]*))$") end --A function to split path to path, name, extension.

local Peripherals = {} --The loaded peripherals.
local MPer = {} --Mounted and initialized peripherals.
local BPer = {} --Peripherals ready for use IN the BIOS only.
local Devkits = {} --Peripherals Devkits.
local InDirect = {} --Peripherals indirect list.
local DirectAPI = false --An important feature to speed up Peripherals functions calling, calls them directly instead of yeilding the coroutine.

--A function to load the peripherals.
local function indexPeripherals(path)
  local files = love.filesystem.getDirectoryItems(path)
  for k,filename in ipairs(files) do
    if love.filesystem.isDirectory(path..filename) then
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
  
  events:group(per..":"..m)
  local success, peripheral, devkit, indirect = pcall(Peripherals[per],conf)
  events:group()
  
  if success then
    MPer[m] = peripheral
    Devkits[m] = devkit
    InDirect[m] = {}
    for k,v in ipairs(indirect or {}) do
      InDirect[m][v] = true
    end
    coreg:register(peripheral,m)
  else
    peripheral = "Init Err: "..tostring(peripheral)
  end
  return success, peripheral, devkit, nocache
end

if not love.filesystem.exists("/bconf.lua") or love.filesystem.exists("devmode.txt") then
  love.filesystem.write("/bconf.lua",love.filesystem.read("/BIOS/bconf.lua"))
end

local passert = function(ok, per, devkit) --Peripheral assert
  if not ok then return error(per) end
  return per, devkit
end

local confSandbox = {P = P,error=error,assert=passert,_OS=love.system.getOS()}

local ok, bchunk, err = pcall(love.filesystem.load,"/bconf.lua")
--if not bconfC then bconfC, bconfDErr = love.filesystem.load("/BIOS/bconf.lua") end --Load the default BConfig
if not ok then error(bchunk) end
if not bchunk then error(err) end
setfenv(bchunk,confSandbox) --BConfig sandboxing
local success, run_err = pcall(bchunk)
if not success then error(run_err)
  local ok, default_bchunk, err = pcall(love.filesystem.load,"/BIOS/bconf.lua")
  if not ok then error(default_bchunk) end
  if not default_bchunk then error(err) end
  setfenv(default_bchunk,confSandbox) --BConfig sandboxing
  default_bchunk()
end --Load the default BConfig

DirectAPI = confSandbox._DirectAPI

if DirectAPI then --Build the cache
  DirectAPI = {} --Convert it to a table.
  for per, funcs in pairs(MPer) do
    DirectAPI[per] = {}
    for fname, func in pairs(funcs) do
      if not InDirect[per][fname] then --Cache it
        DirectAPI[per][fname] = function(...)
          local result = {func(...)}
          if result[1] then --It ran successfully
            local nres = {}
            for k,v in ipairs(result) do
              nres[k-1] = v
            end
            return unpack(nres)
          else --Error
            return error(result[2] or "Unknown")
          end
        end
      end
    end
  end
end

--BIOS Api for use in the OS
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

coreg:register(function()
  return true, DirectAPI
end,"BIOS:DirectAPI")

local function exe(...) --Execute a LIKO12 api function (to handle errors)
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

--Setup Peripherals for use in the BIOS
for name, per in pairs(MPer) do
  if type(per) == "table" then
    BPer[name] = {}
    for fname, func in pairs(per) do
      local f = func
      BPer[name][fname] = function(...) return exe(f(...)) end
    end
  end
end

--Setup shortcuts for use.
local fs = BPer.HDD
local gpu = BPer.GPU
local cpu = BPer.CPU
local ram = BPer.RAM
local ramkit = Devkits.RAM
local keyboard = BPer.Keyboard
local floppy = BPer.Floppy

if not fs then error("No HDD peripheral to boot from !") end

--Installs a specific OS on the drive C
local function installOS(os,path)
  local path = path or "/"
  local files = love.filesystem.getDirectoryItems("/OS/"..os..path)
  for k,v in pairs(files) do
    if love.filesystem.isDirectory("/OS/"..os..path..v) then
      fs.newDirectory(path..v)
      installOS(os,path..v.."/")
    else
      fs.drive("C") --Opereating systems are installed on C drive
      fs.write(path..v,love.filesystem.read("/OS/"..os..path..v))
    end
  end
end

--Called when there is no opereating system to boot from on the C drive.
local function noOS()
  if gpu then --Show a gui asking to install diskos.
    installOS("DiskOS")
  else --Install diskos directly ;)
    installOS("DiskOS")
  end
end

--Boots into the install opreating system, creates the coroutine, sandboxes it and start !
local function bootOS()
  fs.drive("C") --Switch to the C drive.
  
  if not fs.exists("/boot.lua") or love.filesystem.exists("devmode.txt") then noOS() end
  
  local bootchunk, err = fs.load("/boot.lua")
  if not bootchunk then error(err or "") end --Must be replaced with an error screen.
  
  local coglob = coreg:sandbox(bootchunk)
  local co = coroutine.create(bootchunk)
  coreg:setCoroutine(co,coglob) --For peripherals to use.
  
  if cpu then cpu.clearEStack() end --Remove any events made while booting.
  
  coreg:resumeCoroutine() --Boot the OS !
end

if gpu then
  --Post Screen--
  gpu.clear() --Fill with black.
  gpu.color(7) --Set the color to white.
  
  --Load the bios logos.
  local lualogo = gpu.image(love.filesystem.read("/BIOS/lualogo.lk12"))
  local likologo = gpu.image(love.filesystem.read("/BIOS/likologo.lk12"))
  
  local sw, sh = gpu.screenSize()
  
  local stages = {0.5,0,0.3,0,0.3,0,1.5,0.2,0}
  local timer = 0
  local stage = 1
  
  events:group("BIOS:POST")
  events:register("love:update", function(dt)
    if stage > #stages then return end
    
    if stage == 2 then
      lualogo:draw(sw-lualogo:width()-6,5)
      likologo:draw(2,7)
      
      gpu.print("LIKO-12 - Fantasy Computer",15,6)
      gpu.print("Copyright (C) Rami Sabbagh",15,13)
      
      gpu.printCursor(0,3,0)
      gpu.print("NormBIOS Revision 060-009")
      gpu.print("")
      
      gpu.print("Press DEL to enter setup",2,sh-7)
      
    elseif stage == 4 then
      gpu.print("Main CPU: LuaJIT 5.1")
      if ram then gpu.print("RAM: "..(ramkit.ramsize/1024).." Kilo-Bytes ("..ramkit.ramsize.." Bytes)") end
      gpu.print("GPU: "..sw.."x"..sh.." 4-Bit (16 Color Palette)")
      gpu.print("")
      gpu.print("Harddisks: ")
    elseif stage == 6 then
      Devkits["HDD"].calcUsage()
      for letter,drive in pairs(Devkits["HDD"].drives) do
        local size = math.floor((drive.size/1024) * 100)/100
        local usage = math.floor((drive.usage/1024) * 100)/100
        local percentage = math.floor(((usage*100)/size) * 100)/100
        gpu.print("Drive "..letter..": "..usage.."/"..size.." KB ("..percentage.."%)")
      end
    elseif stage == 8 then
      gpu.clear()
      gpu.printCursor(0,0,0)
    elseif stage == 9 then
      events:unregisterGroup("BIOS:POST")
      bootOS()
    end
    
    timer = timer + dt
    if timer > stages[stage] then
      stage = stage + 1
      timer = 0
    end
  end)
else
  Devkits["HDD"].calcUsage()
  bootOS() --Incase the gpu doesn't exists (Then can't enter the bios nor do the boot animation
end