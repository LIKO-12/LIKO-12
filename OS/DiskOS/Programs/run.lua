--This file loads a lk12 disk and execute it

--First we will start by obtaining the disk data
--We will run the current code in the editor
local eapi = require("C://Editors")
local mapobj = require("C://Libraries/map")

local sprid = 3 --"spritesheet"
local codeid = 2 --"luacode"
local tileid = 4 --"tilemap"

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

--Create the sandboxed global variables
local glob = _FreshGlobals()
glob._G = glob --Magic ;)

glob.loadstring = function(...)
 local chunk, err = loadstring(...)
 if not chunk then return nil, err end
 setfenv(chunk,glob)
 return chunk
end

glob.coroutine.create = function(chunk)
 --if type(chunk) == "function" then setfenv(chunk,glob) end
 local ok,co = pcall(coroutine.create,chunk)
 if not ok then return error(co) end
 return co 
end

--Add peripherals api
local blocklist = { HDD = true, Floppy = true }
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

local apiloader = loadstring(fs.read("C://api.lua"))
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
glob["__".."_".."autoEventLoop"] = autoEventLoop --Because trible _ are not allowed in LIKO-12

local helpersloader, err = loadstring(fs.read("C://Libraries/diskHelpers.lua"))
if not helpersloader then error(err) end
setfenv(helpersloader,glob) helpersloader()

--Apply the sandbox
setfenv(diskchunk,glob)

--Create the coroutine
local co = coroutine.create(diskchunk)

--Too Long Without Yielding
local checkclock = true
local eventclock = os.clock()
local lastclock = os.clock()
coroutine.sethook(co,function()
  if os.clock() > lastclock + 3.5 and checkclock then
    error("Too Long Without Yielding",2)
  end
end,"",10000)

--Run the thing !
local function extractArgs(args,factor)
  local nargs = {}
  for k,v in ipairs(args) do
    if k > factor then table.insert(nargs,v) end
  end
  return nargs
end

local lastArgs = {}
while true do
  if coroutine.status(co) == "dead" then break end
  
  --[[local name, key = rawPullEvent()
  if name == "keypressed" and key == "escape" then
    break
  end]]
  
  if os.clock() > eventclock + 3.5 then
    color(8) print("Too Long Without Pulling Event / Flipping") break
  end
  
  local args = {coroutine.resume(co,unpack(lastArgs))}
  checkclock = false
  if not args[1] then
    local err = tostring(args[2])
    local pos = string.find(err,":") or 0
    err = err:sub(pos+1,-1); color(8) print("ERR: "..err ); break
  end
  if args[2] then
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
    lastclock = os.clock()
    checkclock = true
  end
end

coroutine.sethook(co)
clearEStack()
print("")