--The BIOS should control the system of LIKO-12 and load the peripherals--
--For now it's just a simple BIOS to get LIKO-12 working.
local BuildMode = love.filesystem.getInfo("build.json") and true or false

local json = require("Engine.JSON")

if BuildMode then
  BuildMode = json:decode(love.filesystem.read("build.json"))
end

if not love.filesystem.getInfo("Miscellaneous","directory") then
  love.filesystem.createDirectory("Miscellaneous")
end

local _LIKO_Version, _LIKO_Old, _FirstBoot = _LVERSION:sub(2,-1)
if love.filesystem.getInfo("Miscellaneous/.version","file") then
  _LIKO_Old = love.filesystem.read("Miscellaneous/.version")
  if _LIKO_Old == _LIKO_Version then
    _LIKO_Old = false
  end
else
  love.filesystem.write("Miscellaneous/.version",tostring(_LIKO_Version))
  _FirstBoot = true
end

--Require the engine libraries--
local coreg = require("Engine.coreg")

local function splitFilePath(path) return path:match("(.-)([^\\/]-%.?([^%.\\/]*))$") end --A function to split path to path, name, extension.

local Peripherals = {} --The loaded peripherals chunks.
local APIS = {} --The initialized peripherals apis.
local yAPIS = {} --The initialized peripherals yielding apis.
local Mounted = {} --The mounted peripherals list and types.
local Handled = {} --The handled peripherals functions.
local Devkits = {} --The mounted peripherals devkits.

--A function to load the peripherals.
local function indexPeripherals(path)
  local files = love.filesystem.getDirectoryItems(path)
  for k,filename in ipairs(files) do
    if love.filesystem.getInfo(path..filename,"directory") then
      if love.filesystem.getInfo(path..filename.."/init.lua","file") then
        local chunk, err = love.filesystem.load(path..filename.."/init.lua")
        if not chunk then Peripherals[filename] = "Err: "..tostring(err) else
        Peripherals[filename] = chunk(path..filename.."/") end
      end
    else
      --luacheck: push ignore 211
      local p, n, e = splitFilePath(path..filename)
      --luacheck: pop
      if e == "lua" then
        local chunk, err = love.filesystem.load(path..n)
        if not chunk then Peripherals[n:sub(0,-5)] = "Err: "..tostring(err) else
        Peripherals[n:sub(0,-5)] = chunk(path) end
      end
    end
  end
end

indexPeripherals("/Peripherals/") --Index and Load the peripherals

--Initializes a specific peripheral, and mount it under a specific name.
--Peripheral, Err = P(PeriheralName, MountedName, ConfigTabel)
local function P(per,m,conf)
  if not per then return false, "Should provide peripheral name" end
  if type(per) ~= "string" then return false, "Peripheral name should be a string, provided "..type(per) end
  if not Peripherals[per] then return false, "'"..per.."' Peripheral doesn't exists" end
  if type(Peripherals[per]) == "string" then return false, "Compile "..Peripherals[per] end
  
  m = m or per
  if type(m) ~= "string" then return false, "Mounting name should be a string, provided "..type(m) end
  if Mounted[m] then return false, "Mounting name '"..m.."' is already taken" end
  
  conf = conf or {}
  if type(conf) ~= "table" then return false, "Configuration table should be a table, provided "..type(conf) end
  
  local success, API, yAPI, devkit = pcall(Peripherals[per],conf)
  
  if success then
    APIS[m] = API or {} --The direct API
    yAPIS[m] = yAPI or {} --The yielding API
    Mounted[m] = per --The peripheral type
    Devkits[m] = devkit or {} --The peripheral Devkit.
  else
    API = "Init Err: "..tostring(API)
  end
  
  return success, API, yAPI, devkit
end

--Initialize a peripheral, and crash LIKO-12 if failed.
local function PA(...)
  local ok, api, yapi, devkit = P(...)
  if ok then
    return api, yapi, devkit
  else
    return error(tostring(api))
  end
end

--BIOS APIS--
do
  
  Mounted.BIOS = "BIOS"
  APIS.BIOS = {}
  yAPIS.BIOS = {}

  --Returns a list of mounted peripherals and their types.
  function yAPIS.BIOS.Peripherals()
    local pList = {}
    
    for mountName, pType in pairs(Mounted) do
      pList[mountName] = pType
    end
    
    return true, pList
  end

  --Returns the handled peripherals APIS, that can be used directly.
  function yAPIS.BIOS.HandledAPIS()
    local hAPIS = {}
    
    for mountName,funcList in pairs(Handled) do
      hAPIS[mountName] = {}
      for funcName, func in pairs(funcList) do
        hAPIS[mountName][funcName] = func
      end
    end
    
    return true, hAPIS
  end

  --Returns the list of available peripheral functions, and their type (Direct,Yield).
  function yAPIS.BIOS.PeripheralFunctions(mountName)
    if type(mountName) ~= "string" then return false, "MountName should be a string, provided: "..type(mountName) end
    if not Mounted[mountName] then return false, "No mounted peripheral '"..mountName"..'" end
    
    local funcList = {}
    
    for funcName, func in pairs(APIS[mountName]) do
      funcList[funcName] = "Direct"
    end
    
    for funcName, func in pairs(yAPIS[mountName]) do
      funcList[funcName] = "Yield"
    end
    
    return true, funcList
  end
  
  --Returns LIKO-12's Version.
  function yAPIS.BIOS.getVersion()
    return true, _LIKO_Version, _LIKO_Old
  end
  
  --Tells if this is the first boot of LIKO-12 ever.
  function yAPIS.BIOS.isFirstBoot()
    return true, _FirstBoot or false
  end
  
  --Returns LIKO-12_Source.love data.
  function yAPIS.BIOS.getSRC()
    if not love.filesystem.getInfo("/Miscellaneous/LIKO-12_Source.love") then return true, false, "LIKO-12_Source.love doesn't exist ! Try to reboot." end
    
    return true, love.filesystem.read("/Miscellaneous/LIKO-12_Source.love")
  end
  
end

--The BIOS config sandbox
local bconfSandbox = {
  P=P, PA=PA,
  error=error, assert=assert,
  _OS = love.system.getOS(),
  Build = BuildMode
}

--Load and execute the bios config
local bconfChunk = love.filesystem.load(BuildMode and "BIOS/bconf_splash.lua" or "BIOS/bconf.lua")
setfenv(bconfChunk, bconfSandbox)
bconfChunk(BuildMode)

--Register yielding APIS
for mountName, yAPI in pairs(yAPIS) do
  coreg.register(yAPI,mountName)
end

--Create handled functions
for mountName, pType in pairs(Mounted) do
  Handled[mountName] = {}
  
  for funcName, func in pairs(APIS[mountName]) do
    Handled[mountName][funcName] = func
  end
  
  for funcName, func in pairs(yAPIS[mountName]) do
    local funcCommand = mountName..":"..funcName
    Handled[mountName][funcName] = function(...)
      local respond = {coroutine.yield(funcCommand,...)}
      if respond[1] then
        return select(2,unpack(respond))
      else
        return error(tostring(respond[2]))
      end
    end
  end
end

--Bootup the POST chunk
local POST = love.filesystem.load(BuildMode and "/BIOS/splash.lua" or "/BIOS/post.lua")
local POSTCo = coroutine.create(POST)

coreg.setCoroutine(POSTCo)
coreg.resumeCoroutine(Handled,Devkits)