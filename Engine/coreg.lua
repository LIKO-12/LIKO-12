--Corouting Registry: this file is responsible for providing LIKO12 it's api--
local coreg = {reg={}}

local registry = {}
local likoCoroutine, likoGlob

local sandbox = require("Engine.sandbox")

--Args: table, shift
local function shiftTable(a,b)b=b-1;for c=b+1,#a+b do a[c-b]=a[c]end end

--Returns the current active coroutine if exists
function coreg.getCoroutine()
  return likoCoroutine, likoGlob
end

--Sets the current active coroutine
function coreg.setCoroutine(co,glob)
  likoCoroutine  = co or likoCoroutine
  likoGlob = glob or likoGlob
  return coreg
end

--Resumes the current active coroutine if exists.
function coreg.resumeCoroutine(...)
  local lastargs = {...}
  while true do
    if not likoCoroutine or coroutine.status(likoCoroutine) == "dead" then
      return error(likoCoroutine and "The coroutine is dead" or "No coroutine to execute !")
    end
    
    local args = {coroutine.resume(likoCoroutine,unpack(lastargs))}
    
    if not args[1] then error(args[2]) end --Should have a better error handelling
    
    if coroutine.status(likoCoroutine) == "dead" then
      
      --The coroutine finished, we hope that a new one has been set.
      
    elseif tostring(args[2]) == "echo" then
      
      shiftTable(args,3)
      lastargs = args
      
    elseif args[2] then --There's a command to process
      args = {coreg.trigger(select(2,unpack(args)))}
      if not args[1] then --That's a failure
        lastargs = args --Let's pass it to the coroutine.
      elseif not(type(args[1]) == "number" and args[1] == 2) then --Continue with the loop
        lastargs = args --Let's pass it to the coroutine.
      else --The registered function will call resumeCoroutine() later some how, exit the loop now.
        return
      end
    end
  end
end

--Sandbox a function with the current coroutine environment.
function coreg.sandbox(f)
  if likoCoroutine and likoGlob then setfenv(f,likoGlob) return end
  local GLOB = sandbox(coreg.getCoroutine) --Create a new sandbox.
  
  setfenv(f,GLOB)
  return GLOB
end

--[[
Register a value to a specific key.
If the value is a table, then the values in the table will be registered at key:tableValueKey
If the value is a function, then it will be called instantly,
  and it must return true as the first argument to tell that it ran successfully.
Else, the value will be returned to the liko12 code.
]]
function coreg.register(value,key)
  key = key or "none"
  if type(value) == "table" then
    for k,v in pairs(value) do
      registry[key..":"..k] = v
    end
  end
  registry[key] = value
end

--[[
Trigger a value in a key.
If the value is a function, then it will call it instant.
Else, it will return the value.
Notice that the first return value is a number of "did it ran successfully",
  if false, the second return value is the error message.
Also the first return value could be also a number that specifies how should the coroutine resume
  (true boolean defaults to 1)
Corouting resumming codes: 1: resume instantly, 2: stop resuming (Will be yeild later, like when love.update is called).
]]
function coreg.trigger(key,...)
  key = key or "none"
  if type(registry[key]) == "nil" then return false, "error, key not found !" end
  if type(registry[key]) == "function" then
    return registry[key](...)
  else
    return true, registry[key]
  end
end

--Returns the value registered in a specific key.
--Returns: value then the given key.
function coreg.get(key)
  key = key or "none"
  return registry[key], key
end

--Returns a table containing the list of the registered keys.
--list[key] = type
function coreg.index()
  local list = {}
  for k,v in pairs(registry) do
    list[k] = type(v)
  end
  return list
end

--Returns a clone of the registry table.
function coreg.registry()
  local reg = {}
  for k,v in pairs(registry) do
    reg[k] = v
  end
  return reg
end

return coreg