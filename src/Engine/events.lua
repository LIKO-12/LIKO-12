--==Contribution Guide==--
--[[
Events System, used for wiring love events to LIKO-12's peripherals.

Event Name:
* It's highly recommended to name event as "parent:funcName", for ex: "love:update".

LOVE Hooks:
* All love callbacks are triggered with names "love:callbackName", ex: "love:mousepressed".
* There is 3 special love events:
- "love:graphics" called then the love.graphics module is active and it's turn to draw in love.run.
- "love:reboot" Trigger this event with a table of args to pass after SOFT rebooting (to love.load).
- "love:quit" if any registered function returns true the quit will be cancelled.

local registry:
- It's a table that contains tables, the keys of this table is the name of register function,
  and the value is a table containing all the registered function with the same name.

How events works:
 * Registering a function (events.register): registering means adding a function
     to be called when a specific event is triggered.
 * Triggering an event (events.trigger): will call all the registered functions with a specific event name.

events.triggerWithReturns:
 * Returns a table containing tables of what each triggered function returned.

==Contributors to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

local events = {}
local registry = {}

function events.register(name,func)
  if type(name) ~= "string" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  if type(func) ~= "function" then return error("func should be a function value. Passed "..type(func).." instead !") end
  
  if not registry[name] then registry[name] = {} end
  registry[name][#registry[name] + 1] = func
  
  return events
end

function events.trigger(name,...)
  if type(name) ~= "string" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  local funcs = registry[name]
  if not funcs then return end
  
  for i=1, #funcs do
    funcs[i](...)
  end
  
  return events
end

function events.triggerWithReturns(name,...)
  if type(name) ~= "string" then return error("Name should be a string value. Passed "..type(name).." instead !") end
  local funcs = registry[name]
  if not funcs then return end
  
  local returns = {}
  for i=1, #funcs do
    returns[i] = {funcs[i](...)}
  end
  
  return returns
end

return events