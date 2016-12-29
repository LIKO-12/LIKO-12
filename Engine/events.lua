--This file is responsible for wiring love events to liko12s peripherals.
local events = {reg={}}

--Register a function to an event.
function events:register(name,func)
  if type(name) ~= "string" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  if type(func) ~= "function" then return error("func should be a function value. Passed "..type(func).." instead !") end
  if not self.reg[name] then self.reg[name] = {} end
  self.reg[name][func] = func
  return self
end

--Unregister a function from the events system.
function events:unregister(func,name) --Name is optional
  if type(name) ~= "string" and type(name) ~= "nil" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  if type(func) ~= "function" then return error("func should be a function value. Passed "..type(func).." instead !") end
  if name and self.reg[name] then
    self.reg[name][func] = nil
  else --Search through all events
    for k,v in pairs(self.reg) do
      v[func] = nil
    end
  end
  return self
end

--Call an event functions
--Returns a table with the responds of the functions, with functions as the keyvalue.
function events:trigger(name,...)
  if type(name) ~= "string" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  if not self.reg[name] then return {} end
  local r = {}
  for k,f in pairs(self.reg[name]) do
    r[f] = {f(...)}
  end
  return r
end

return events