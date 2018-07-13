--==Contribution Guide==--
--[[
Events System, used for wiring love events to liko12s peripherals.

Event Name:
* It's highly recommended to name event as "parent:funcName", for ex: "love:update".

Love2D Hooks:
* All love2d callbacks are triggered with names "love:callbackName", ex: "love:mousepressed".
* There is 2 special love2d events:
- "love:graphics" called then the love.graphics module is active and it's turn to draw in love.run.
- "love:reboot" Trigger this event with a table of args to pass after SOFT rebooting.
- "love:quit" if any registered function returns true the quit will be cancelled.

NormBIOS:
* It does automatically switch the group name for each peripheral with name "peripheralName:mountName".
* When unmounting a peripheral it does automatically unregisters the events of it.

events.reg:
- It's a table that contains table, the keys of this table is the name of register function, and the value is a table containing all the registered function with the same name.

events.groups:
- It's a table, where the index is the group name, and the value is the group table:
- Each group table contains tables, where each index is the function name, and the value is a table which contains the ids of each registered function.
- Inorder to find a function in the events.reg, you may do: events.reg[funcname][id]()

How events works:
 * Registering a function: registering means adding a function to be called when a specific event is triggered.
 * Triggering an event: will call all the registered functions with a specific event name.
 * Groups are like sorting the registered events to their "owner name", so they can be registered togather instead of each one itself.
 * Calling event:group with not arguments will set to the default group which is called "Unsorted"
 * Groups name must be a string.

==Contributors to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

local events = {reg={},groups={}}

--Adds functions when registered to a specific group.
--When called by nil it will register them unsorted.
function events:group(name)
  local name = name or "Unsorted"
  if not self.groups[name] then
    self.groups[name] = {} --Create a new group
  end
  self.activeGroup = self.groups[name]
  return self
end

events:group() --Setup the Unlisted Group.

--Register a function to an event.
function events:register(name,func)
  if type(name) ~= "string" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  if type(func) ~= "function" then return error("func should be a function value. Passed "..type(func).." instead !") end
  if not self.reg[name] then self.reg[name] = {} end
  if not self.activeGroup[name] then self.activeGroup[name] = {} end
  table.insert(self.reg[name],func)
  table.insert(self.activeGroup[name],#self.reg[name])
  return func
end

--Unregister a function from the events system.
function events:unregister(func,name) --Name is optional
  if type(name) ~= "string" and type(name) ~= "nil" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  if type(func) ~= "function" then return error("func should be a function value. Passed "..type(func).." instead !") end
  if name and self.reg[name] then
    for k,v in ipairs(self.reg[name]) do
      if v == func then
        table.remove(self.reg[name],k)
      end
    end
    --Clear the gaps
    local newList = {}
    local gapCount = 0
    for k,v in ipairs(self.reg[name]) do
      if type(v) == "nil" then
        gapCount = gapCount+1
      else
        table.insert(newList,k-gapCount,v)
      end
    end
    self.reg[name] = newList
  else --Search through all events
    for rk,rv in pairs(self.reg) do
      for k,v in ipairs(rv) do
        if v == func then
          table.remove(rv,k)
        end
      end
      --Clear the gaps
      local newList = {}
      local gapCount = 0
      for k,v in ipairs(rv) do
        if type(v) == "nil" then
          gapCount = gapCount+1
        else
          table.insert(newList,k-gapCount,v)
        end
      end
      self.reg[rk] = newList
    end
  end
  return self
end

function events:unregisterGroup(gname)
  if not self.groups[gname] then return self end
  
  for name,funcs in pairs(self.groups[gname]) do
    for k,id in ipairs(funcs) do
      if self.reg[name][id] then
        table.remove(self.reg[name],id)
      end
    end
    --Clear the gaps
    local newList = {}
    local gapCount = 0
    for k,v in ipairs(self.reg[name]) do
      if type(v) == "nil" then
        gapCount = gapCount+1
      else
        table.insert(newList,k-gapCount,v)
      end
    end
    self.reg[name] = newList
  end
  
  self.groups[gname] = nil
  
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