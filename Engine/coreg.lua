--Corouting Registry: this file is responsible for providing LIKO12 it's api--
local coreg = {reg={},stack={}}

local sandbox = require("Engine.sandbox")

--Returns the current active coroutine if exists
function coreg:getCoroutine()
  return self.co, self.coglob
end

--Sets the current active coroutine
function coreg:setCoroutine(co,glob)
  self.co  = co or self.co
  self.coglob = glob or self.coglob
  return self
end

--Push the current coroutine to the coroutine stack,
-- and set the current coroutine to nil
function coreg:pushCoroutine()
  table.insert(self.stack,self.co)
  self.co = nil
end

--Pop a coroutine from the coroutine stack.
function coreg:popCoroutine()
  if #self.stack < 1 then return error("No coroutines in the stack") end
  self.co = self.stack[1]
  for i=2,#self.stack do
    self.stack[i-1] = self.stack[i]
  end
  self.stack[#self.stack] = nil
end

--Resumes the current active coroutine if exists.
function coreg:resumeCoroutine(...)
  local lastargs = {...}
  while true do
    if not self.co or coroutine.status(self.co) == "dead" then return end
    local args = {coroutine.resume(self.co,unpack(lastargs))}
    if not args[1] then error(args[2]) end --Should have a better error handelling
    if not args[2] then
      self.os = nil; return
    end
    args = {self:trigger(select(2,unpack(args)))}
    if not args[1] then lastargs = args
    elseif not(type(args[1]) == "number" and args[1] == 2) then
      lastargs = {true,select(2,unpack(args))}
    else break end
  end
end

function coreg:sandbox(f)
  if self.co and self.coglob then setfenv(f,self.coglob) return end
  local GLOB = sandbox(self) --Create a new sandbox.
  
  setfenv(f,GLOB)
  return GLOB
end

--Register a value to a specific key.
--If the value is a table, then the values in the table will be registered at key:tableValueKey
--If the value is a function, then it will be called instantly, and it must return true as the first argument to tell that it ran successfully.
--Else, the value will be returned to the liko12 code.
function coreg:register(value,key)
  local key = key or "none"
  if type(value) == "table" then
    for k,v in pairs(value) do
      self.reg[key..":"..k] = v
    end
  end
  self.reg[key] = value
end

--Trigger a value in a key.
--If the value is a function, then it will call it instant.
--Else, it will return the value.
--Notice that the first return value is a number of "did it ran successfully", if false, the second return value is the error message.
--Also the first return value could be also a number that specifies how should the coroutine resume (true boolean defaults to 1)
--Corouting resumming codes: 1: resume instantly, 2: stop resuming (Will be yeild later, like when love.update is called).
function coreg:trigger(key,...)
  local key = key or "none"
  if type(self.reg[key]) == "nil" then return false, "error, key not found !" end
  if type(self.reg[key]) == "function" then
    return self.reg[key](...)
  else
    return true, self.reg[key]
  end
end

--Returns the value registered in a specific key.
--Returns: value then the given key.
function coreg:get(key)
  local key = key or "none"
  return self.reg[key], key
end

--Returns a table containing the list of the registered keys.
--list[key] = type
function coreg:index()
  local list = {}
  for k,v in pairs(self.reg) do
    list[k] = type(v)
  end
  return list
end

--Returns a clone of the registry table.
function coreg:registry()
  local reg = {}
  for k,v in pairs(self.reg) do
    reg[k] = v
  end
  return reg
end

return coreg