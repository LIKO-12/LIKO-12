--This file loads a lk12 disk and executes it
if select(1,...) == "-?" then
  printUsage(
    "run [...]","Runs the current loaded game with any provided arguments"
  )
  return
end

--First we will start by obtaining the disk data
--We will run the current code in the editor
local term = require("terminal")
local eapi = require("Editors")
local mapobj = require("Libraries/map")
local sfxobj = require("Libraries/sfx")

local sprid = eapi.editors.sprite
local codeid = eapi.editors.code
local tileid = eapi.editors.tile
local sfxid = eapi.editors.sfx

local swidth, sheight = screenSize()

--Load the spritesheet
local SpriteMap, FlagsData
local sheetImage = image(eapi.leditors[sprid]:exportImage())
local FlagsData = eapi.leditors[sprid]:getFlags()
local sheetW, sheetH = sheetImage:width()/8, sheetImage:height()/8
SpriteMap = SpriteSheet(sheetImage,sheetW,sheetH)

--Load the tilemap
local mapData = eapi.leditors[tileid]:export()
local mapW, mapH = swidth*0.75, sheight
local TileMap = mapobj(mapW,mapH,SpriteMap)
TileMap:import(mapData)

--Load the sfx
local sfxData = eapi.leditors[sfxid]:export():gsub("\n","")
local SFXList, SFXListPos = {}, 0
for sfxstr in sfxData:gmatch("(.-);") do
  local s = sfxobj(32)
  s:import(sfxstr..",")
  SFXList[SFXListPos] = s
  SFXListPos = SFXListPos + 1
end

--Load the code
local luacode = eapi.leditors[codeid]:export()
luacode = luacode .. "\n__".."_autoEventLoop()" --Because trible _ are not allowed in LIKO-12
local diskchunk, err = loadstring(luacode)
if not diskchunk then
  local err = tostring(err)
  local pos = string.find(err,":")
  err = err:sub(pos+1,-1)
  color(8) print("Compile ERR: "..err )
  return
end

--Create the sandboxed global variables
local glob = _FreshGlobals()
glob._G = glob --Magic ;)

local co

glob.getfenv = function(f)
  if type(f) ~= "function" then return error("bad argument #1 to 'getfenv' (function expected, got "..type(f)) end
  local ok, env = pcall(getfenv,f)
  if not ok then return error(env) end
  if env == _G then env = {} end --Protection
  return env
end
glob.setfenv = function(f,env)
  if type(f) ~= "function" then return error("bad argument #1 to 'setfenv' (function expected, got "..type(f)) end
  if type(env) ~= "table" then return error("bad argument #2 to 'setfenv' (table expected, got "..type(env)) end
  local oldenv = getfenv(f)
  if oldenv == _G then return end --Trying to make a crash ! evil.
  local ok, err = pcall(setfenv,f,env)
  if not ok then return error(err) end
end
glob.loadstring = function(data)
  local chunk, err = loadstring(data)
  if not chunk then return nil, err end
  setfenv(chunk,glob)
  return chunk
end
glob.coroutine.running = function()
  local curco = coroutine.running()
  if co and curco == co then return end
  return curco
end

--Add peripherals api
local blocklist = { HDD = true, WEB = true, FDD = true, BIOS = true }
local perglob = {GPU = true, CPU = true, Keyboard = true, RAM = true} --The perihperals to make global not in a table.

local handledapis = BIOS.HandledAPIS()
for peripheral, funcList in pairs(handledapis) do
  if not blocklist[peripheral] then
    for funcName, func in pairs(funcList) do
      if funcName:sub(1,1) == "_" then
        funcList[funcName] = nil
      elseif perglob[peripheral] then
        glob[funcName] = func
      end
    end
    
    glob[peripheral] = funcList
  end
end

local apiloader = fs.load("C:/System/api.lua")
setfenv(apiloader,glob) apiloader()

local function autoEventLoop()
  if glob._init and type(glob._init) == "function" then
    glob._init()
  end
  if type(glob._eventLoop) == "boolean" and not glob._eventLoop then return end --Skip the auto eventLoop.
  if glob._update or glob._draw or glob._eventLoop then
    eventLoop()
  end
end

setfenv(autoEventLoop,glob)

--Add special disk api
glob.SpriteMap = SpriteMap
glob.SheetFlagsData = FlagsData
glob.TileMap = TileMap
glob.MapObj = mapobj
glob.SFXS = SFXList
glob.SfxObj = sfxobj

local json = require("Libraries/JSON")

local pkeys = {} --Pressed keys
local rkeys = {} --Repeated keys
local dkeys = {} --Down keys
local tbtn = {false,false,false,false,false,false,false} --Touch buttons
local gpads = {} --Gamepads

local defaultbmap = {
  {"left","right","up","down","z","x","c"}, --Player 1
  {"s","f","e","d","tab","q","w"} --Player 2
}

if not fs.exists("C:/keymap.json") then
  fs.write("C:/keymap.json",json:encode_pretty(defaultbmap))
end

do --So I can hide this part in ZeroBran studio
  local bmap = json:decode(fs.read("C:/keymap.json"))

  function glob.btn(n,p)
    local p = p or 1
    if type(n) ~= "number" then return error("Button id must be a number, provided: "..type(n)) end
    if type(p) ~= "number" then return error("Player id must be a number or nil, provided: "..type(p)) end
    n, p = math.floor(n), math.floor(p)
    if p < 1  then return error("The Player id is negative ("..p..") it must be positive !") end
    if n < 1 or n > 7 then return error("The Button id is out of range ("..n..") must be [1,7]") end
    
    local map = bmap[p]
    local gmap = gpads[p]
    if not (map or gmap) then return false end --Failed to find a controller
    
    return dkeys[map[n]] or (p == 1 and tbtn[n]) or (gmap and gmap[n])
  end

  function glob.btnp(n,p)
    local p = p or 1
    if type(n) ~= "number" then return error("Button id must be a number, provided: "..type(n)) end
    if type(p) ~= "number" then return error("Player id must be a number or nil, provided: "..type(p)) end
    n, p = math.floor(n), math.floor(p)
    if p < 1  then return error("The Player id is negative ("..p..") it must be positive !") end
    if n < 1 or n > 7 then return error("The Button id is out of range ("..n..") must be [1,7]") end
    
    local map = bmap[p]
    local gmap = gpads[p]
    if not (map or gmap) then return false end --Failed to find a controller
    
    if rkeys[map[n]] or (p == 1 and tbtn[n] and tbtn[n] >= 1) or (gmap and gmap[n] and gmap[n] >= 1) then
      return true, true
    else
      return pkeys[map[n]] or (p == 1 and tbtn[n] and tbtn[n] == 0) or (gmap and gmap[n] and gmap[n] == 0)
    end
  end

  glob.__BTNUpdate = function(dt)
    pkeys = {} --Reset the table (easiest way)
    rkeys = {} --Reset the table (easiest way)
    for k,v in pairs(dkeys) do
      if not isKDown(k) then
        dkeys[k] = nil
      end
    end
    
    for k,v in ipairs(tbtn) do
      if v then
        if tbtn[k] >= 1 then
          tbtn[k] = 0.9
        end
        tbtn[k] = tbtn[k] + dt
      end
    end
    
    for id, gpad in pairs(gpads) do
      for k,v in ipairs(gpad) do
        if v then
          if gpad[k] >= 1 then
            gpad[k] = 0.9
          end
          gpad[k] = gpad[k] + dt
        end
      end
    end
  end

  glob.__BTNKeypressed = function(a,b)
    pkeys[a] = true
    rkeys[a] = b
    dkeys[a] = true
  end
  
  glob.__BTNTouchControl = function(state,n)
    if state then
      tbtn[n] = 0
    else
      tbtn[n] = false
    end
  end
  
  glob.__BTNGamepad = function(state,n,id)
    if not gpads[id] then gpads[id] = {false,false,false,false,false,false} end
    if state then
      gpads[id][n] = 0
    else
      gpads[id][n] = false
    end
  end
end

glob.dofile = function(path)
  local chunk, err = fs.load(path)
  if not chunk then return error(err) end
  setfenv(chunk,glob)
  local ok, err = pcall(chunk)
  if not ok then return error(err) end
end
glob["__".."_".."autoEventLoop"] = autoEventLoop --Because trible _ are not allowed in LIKO-12

--Libraries
local function addLibrary(path,name)
  local lib, err = fs.load(path)
  if not lib then error("Failed to load library ("..name.."): "..err) end
  setfenv(lib,glob) 
  glob[name] = lib()
end

addLibrary("C:/Libraries/lume.lua","lume")
addLibrary("C:/Libraries/middleclass.lua","class")
addLibrary("C:/Libraries/bump.lua","bump")
addLibrary("C:/Libraries/likocam.lua","likocam")
addLibrary("C:/Libraries/JSON.lua","JSON")

local helpersloader, err = fs.load("C:/Libraries/diskHelpers.lua")
if not helpersloader then error(err) end
setfenv(helpersloader,glob) helpersloader()

--Apply the sandbox
setfenv(diskchunk,glob)

--Create the coroutine
co = coroutine.create(diskchunk)

if isMobile() then TC.setInput(true) end
textinput(not isMobile())

--Run the thing !
local function printErr(msg)
  colorPalette() --Reset the palette
  color(8) --Red
  clearMatrixStack()
  clip()
  patternFill()
  print(msg)
end

local lastArgs = {...}
while true do
  if coroutine.status(co) == "dead" then break end
  
  local args = {coroutine.resume(co,unpack(lastArgs))}
  if not args[1] then
    local err = tostring(args[2])
    local pos = string.find(err,":") or 0
    pal() palt() cam() clip() colorPalette()
    err = err:sub(pos+1,-1); printErr("ERR: "..err ); break
  end
  if args[2] then
    if args[2] == "RUN:exit" then break end
    lastArgs = {coroutine.yield(select(2,unpack(args)))}
    if args[2] == "CPU:pullEvent" or args[2] == "CPU:rawPullEvent" or args[2] == "GPU:flip" or args[2] == "CPU:sleep" then
      if args[2] == "GPU:flip" or args[2] == "CPU:sleep" then
        local name, key = rawPullEvent()
        if name == "keypressed" and key == "escape" then
          break
        end
      else
        if lastArgs[1] and lastArgs[2] == "keypressed" and lastArgs[3] == "escape" then
          break
        end
      end
    end
  end
end

clearEStack()
clearMatrixStack()
colorPalette() --Reset the color palette.
clip()
patternFill()

print("")

TC.setInput(false)
Audio.stop()