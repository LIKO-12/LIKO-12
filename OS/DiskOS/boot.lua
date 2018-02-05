local HandledAPIS = ... --select(2,...)

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
for peripheral,funcs in pairs(HandledAPIS) do
  _G[peripheral] = funcs
  
  if perglob[peripheral] then
    for funcName,func in pairs(funcs) do
      _G[funcName] = func
    end
  end
  
  if peripheral == "HDD" then
    _G.fs = funcs
  end
end

--Temp folder
local function rm(path)
  local files = fs.getDirectoryItems(path)
  for k, file in ipairs(files) do
    if fs.isFile(path..file) then
      fs.delete(path..file)
    else
      rm(path..file.."/")
      fs.delete(path..file)
    end
  end
end

if fs.exists("C:/.temp") then
  rm("C:/.temp/")
end
fs.newDirectory("C:/.temp/")

--Create dofile function
function dofile(path,...)
  local chunk, err = fs.load(path)
  if not chunk then return error(tostring(err)) end
  local args = {pcall(chunk,...)}
  if not args[1] then return error(tostring(args[2])) end
  return select(2,unpack(args))
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

--Create the package system--
dofile("C:/System/package.lua")

keyrepeat(true) --Enable keyrepeat
textinput(true) --Show the keyboard on mobile devices

--Load APIS
for k, file in ipairs(fs.getDirectoryItems("C:/APIS/")) do
  dofile("C:/APIS/"..file)
end

dofile("C:/System/api.lua") --Load DiskOS APIs
dofile("C:/System/osapi.lua") --Load DiskOS OS APIs

local terminal = require("terminal")

terminal.init() --Initialize the terminal
terminal.loop()