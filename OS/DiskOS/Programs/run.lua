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

local sprid = eapi.editors.sprite --"spritesheet"
local codeid = eapi.editors.code --"luacode"
local tileid = eapi.editors.tile --"tilemap"

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

--Upload the data to the ram
local SpriteSheetAddr = binToNum(memget(0x0054, 4))
local MapDataAddr = binToNum(memget(0x0058, 4))
local LuaCodeAddr = binToNum(memget(0x0068, 4))
local SpriteFlagsAddr = SpriteSheetAddr + 12*1024

memset(SpriteSheetAddr, imgToBin(sheetImage))
memset(SpriteFlagsAddr, FlagsData)
memset(MapDataAddr, mapToBin(TileMap))
memset(LuaCodeAddr, codeToBin(luacode:sub(1,20*1024)))

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
local blocklist = { HDD = true, WEB = true, Floppy = true }
local perglob = {GPU = true, CPU = true, Keyboard = true, RAM = true} --The perihperals to make global not in a table.

local _,directapi = coroutine.yield("BIOS:DirectAPI"); directapi = directapi or {}
local _,perlist = coroutine.yield("BIOS:listPeripherals")
for k, v in pairs(blocklist) do perlist[k] = nil end
for peripheral,funcs in pairs(perlist) do
 local holder = glob; if not perglob[peripheral] then glob[peripheral] = {}; holder = glob[peripheral] end
 for _,func in ipairs(funcs) do
  if func:sub(1,1) ~= "_" then
   if directapi[peripheral] and directapi[peripheral][func] then
    holder[func] = directapi[peripheral][func]
   else
    local command = peripheral..":"..func
    holder[func] = function(...)
     local args = {coroutine.yield(command,...)}
     if not args[1] then return error(args[2]) end
     local nargs = {}
     for k,v in ipairs(args) do
      if k >1 then table.insert(nargs,k-1,v) end
     end
     return unpack(nargs)
    end
   end
  end
 end
end

local apiloader = loadstring(fs.read("C:/api.lua"))
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
  local lib, err = loadstring(fs.read(path))
  if not lib then error("Failed to load library ("..name.."): "..err) end
  setfenv(lib,glob) 
  glob[name] = lib()
end

addLibrary("C:/Libraries/lume.lua","lume")
addLibrary("C:/Libraries/middleclass.lua","class")
addLibrary("C:/Libraries/bump.lua","bump")

local helpersloader, err = loadstring(fs.read("C:/Libraries/diskHelpers.lua"))
if not helpersloader then error(err) end
setfenv(helpersloader,glob) helpersloader()

--Apply the sandbox
setfenv(diskchunk,glob)

--Create the coroutine
co = coroutine.create(diskchunk)

--Too Long Without Yielding
local checkclock = true
local eventclock = os.clock()

if isMobile() then TC.setInput(true) end
textinput(not isMobile())

--Run the thing !
local function extractArgs(args,factor)
  local nargs = {}
  for k,v in ipairs(args) do
    if k > factor then table.insert(nargs,v) end
  end
  return nargs
end

local function printErr(msg)
  colorPalette() --Reset the palette
  color(8) --Red
  print(msg)
end

local lastArgs = {...}
while true do
  if coroutine.status(co) == "dead" then break end
  
  if os.clock() > eventclock + 3.5 then
    printErr("Too Long Without Pulling Event / Flipping") break
  end
  
  local args = {coroutine.resume(co,unpack(lastArgs))}
  if not args[1] then
    local err = tostring(args[2])
    local pos = string.find(err,":") or 0
    err = err:sub(pos+1,-1); printErr("ERR: "..err ); break
  end
  if args[2] then
    if args[2] == "RUN:exit" then break end
    lastArgs = {coroutine.yield(args[2],unpack(extractArgs(args,2)))}
    if args[2] == "CPU:pullEvent" or args[2] == "CPU:rawPullEvent" or args[2] == "GPU:flip" or args[2] == "CPU:sleep" then
      eventclock = os.clock()
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
colorPalette() --Reset the color palette.
print("")

TC.setInput(false)