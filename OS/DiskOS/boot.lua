--Building the peripherals APIs--
local perglob = {GPU = true, CPU = true, Keyboard = true} --The perihperals to make global not in a table.
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

local terminal = require("C://terminal")
terminal.loop()