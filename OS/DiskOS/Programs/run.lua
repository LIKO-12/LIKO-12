--This file loads a lk12 disk and execute it

--First we will start by obtaining the disk data
--We will run the current code in the editor
local eapi = require("C://Editors")

local sprid = "spritesheet"
local codeid = "luacode"

local diskdata = eapi:export()
diskdata = loadstring(diskdata)()

--Load the spritesheet
local SpriteMap, FlagsData
if diskdata[sprid] then
  local sheetData = diskdata[sprid]
  local w,h,imgdata = string.match(sheetData,"LK12;GPUIMG;(%d+)x(%d+);(.+)")
  local sheetW, sheetH = w/8, h/8
  FlagsData = imgdata:sub(w*h+1,-1)
  if FlagsData:len() < sheetW*sheetH then
    local missing = sheetW*sheetH
    local zerochar = string.char(0)
    for i=1,missing do
      FlagsData = FlagsData..zerochar
    end
  end
  imgdata = imgdata:sub(0,w*h)
  imgdata = "LK12;GPUIMG;"..w.."x"..h..";"..imgdata
  SpriteMap = SpriteSheet(imagedata(imgdata):image(),sheetW,sheetH)
end

--Load the code
local luacode = diskdata[codeid]
local diskchunk = loadstring(luacode)

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
  if type(chunk) == "function" then setfenv(chunk,glob) end
  local ok,co = pcall(coroutine.create,chunk)
  if not ok then return error(co) end
  return co 
end

--Add peripherals api
local blocklist = { HDD = true }

local _,perlist = coroutine.yield("BIOS:listPeripherals")
for k, v in pairs(blocklist) do perlist[v] = nil end
for peripheral,funcs in pairs(perlist) do
  for _,func in ipairs(funcs) do
    local command = peripheral..":"..func
    glob[func] = function(...)
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

local apiloader = loadstring(fs.read("C://api.lua"))
setfenv(apiloader,glob) apiloader()

--Add special disk api
glob.SpriteMap = SpriteMap
glob.SheetFlagsData = FlagsData

--Apply the sandbox
setfenv(diskchunk,glob)

--Create the coroutine
local co = coroutine.create(diskchunk)

--Too Long Without Yielding
local lastclock = os.clock()
coroutine.sethook(co,function()
  if os.clock() > lastclock + 3.5 then
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
  local args = {coroutine.resume(co,unpack(lastArgs))}
  if not args[1] then color(9) print("\nERR: "..tostring(args[2])) break end --Should have a better error handelling
  if args[2] then
    lastArgs = {coroutine.yield(args[2],unpack(extractArgs(args,2)))}
    lastclock = os.clock()
  end
  local name, key = rawPullEvent()
  if name == "keypressed" and key == "escape" then
    break
  end
  --[[if not args[1] then self:resumeCoroutine(args[1],unpack(extractArgs(args,1))) end
  if not(type(args[1]) == "number" and args[1] == 2) then
    self:resumeCoroutine(true,unpack(extractArgs(args,1)))
  end]]
end

coroutine.sethook(co)
clearEStack()