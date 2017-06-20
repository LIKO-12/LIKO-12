--Backup the fresh clean globals
local function copy(t)
  local new = {}
  for k,v in pairs(t) do
    if type(v) == "table" then
      if k ~= "_G" then new[k] = copy(v) end
    else
      new[k] = v
    end
  end
  return new
end

local freshglob = copy(_G)
function _FreshGlobals()
  return copy(freshglob)
end

--Building the peripherals APIs--
local perglob = {GPU = true, CPU = true, Keyboard = true, RAM = true} --The perihperals to make global not in a table.
local _,directapi = coroutine.yield("BIOS:DirectAPI"); directapi = directapi or {}
local _,perlist = coroutine.yield("BIOS:listPeripherals")
for peripheral,funcs in pairs(perlist) do
  local holder
  
  if perglob[peripheral] then
    holder = _G
  else
    --Rename HDD to fs (Easier to spell)
    _G[peripheral == "HDD" and "fs" or peripheral] = {}
    holder = _G[peripheral == "HDD" and "fs" or peripheral]
  end
  
  for _,func in ipairs(funcs) do
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

--A usefull split function
function split(inputstr, sep)
  if sep == nil then sep = "%s" end
  local t={} ; i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

--Restore Require Function--
local function extractArgs(args,factor)
  local nargs = {}
  for k,v in ipairs(args) do
    if k > factor then nargs[k-factor] = v end
  end
  return nargs
end

package = {loaded  = {}} --Fake package system
function require(path,...)
  if type(path) ~= "string" then return error("Require path must be a string, provided: "..type(path)) end
  path = path:gsub("%.","/")
  if package.loaded[path] then return unpack(package.loaded[path]) end
  local origPath = path
  if not fs.exists(path..".lua") then path = path.."/init" end
  local chunk, err = fs.load(path..".lua")
  if not chunk then return error(err or "Load error ("..tostring(path)..")") end
  local args = {pcall(chunk,path,...)}
  if not args[1] then return error(args[2] or "Runtime error") end
  package.loaded[origPath] = extractArgs(args,1)
  return unpack(package.loaded[origPath])
end

keyrepeat(true) --Enable keyrepeat
textinput(true) --Show the keyboard on mobile devices

require("C://api") --Load DiskOS APIs

local SWidth, SHeight = screenSize()

--Setup the RAM
memset(0x0006, "LIKO12;") --The header
local curAddr = 0x000D --Color Palette
for i=0, 15 do
  local r,g,b,a = colorPalette(i)
  poke(curAddr,r)
  poke(curAddr+1,g)
  poke(curAddr+2,b)
  poke(curAddr+3,a)
  curAddr = curAddr+4
end
poke(0x004D,_DiskVer) --Disk Version
poke(0x004E,tonumber(10010001,2)) --Disk Meta
memset(0x004F, numToBin(SWidth,2)) --Screen Width
memset(0x0051, numToBin(SHeight,2)) --Screen Height
memset(0x0054, numToBin(0x02E0 ,4)) --SpriteMap Address

memset(0x0058, numToBin(0x3400 ,4)) --MapData Address
memset(0x005C, numToBin(0x7C00 ,4)) --Instruments Data Address
memset(0x0060, numToBin(0x7C00 ,4)) --Tracks Data Address
memset(0x0064, numToBin(0x7C00 ,4)) --Tracks Orders Address
memset(0x0068, numToBin(0xB000 ,4)) --Compressed Lua Code Address

memset(0x006C, "Unknown         ") --Author Name
memset(0x007C, "DiskOS Game     ") --Game Name

memset(0x008C, numToBin(SWidth,2)) --Spritesheet Width
memset(0x008E, numToBin(SHeight,2)) --Spritesheet Height

memset(0x0090, numToBin(SWidth*0.75,1)) --Map Width
memset(0x0093, numToBin(SHeight,1)) --Map Height

local terminal = require("C://terminal")
terminal.loop()