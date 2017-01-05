--Building the api--
local perglob = {GPU = true, CPU = true, Keyboard = true} --The perihperals to make global not in a table.
local _,perlist = coroutine.yield("BIOS:listPeripherals")
for peripheral,funcs in pairs(perlist) do
  local holder
  
  if perglob[peripheral] then
    holder = _G
  else
    _G[peripheral] = {}
    holder = _G[peripheral]
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

--Rename HDD to fs (Easier to spell)
fs = HDD; HDD = nil

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
  for k,v in ipairs(nargs) do
    if k > factor then nargs[k-factor] = v end
  end
  return nargs
end

package = {loaded  = {}} --Fake package system
function require(path)
  if type(path) ~= "string" then return error("Require path must be a string, provided: "..type(path)) end
  path = path:gsub(".","/")
  if package.loaded[path] then return package.loaded[path] end
  local chunk, err = fs.load(path)
  if not chunk then return error(err) end
  local args = {chunk(path)}
  if not args[1]
  package.loaded[path] = chunk
end