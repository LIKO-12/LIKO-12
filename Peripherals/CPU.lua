local events = require("Engine.events")
local coreg = require("Engine.coreg")

return function(config) --A function that creates a new CPU peripheral.
  local EventStack = {}
  local Instant = false
  
  local function hookEvent(pre,name)
    events:register(pre..":"..name,function(...)
    if Instant then
      Instant = false coreg:resumeCoroutine(true,name,...)
    else
      --[[local args = {...}
      local nargs = {name}
      for k,v in ipairs(args) do table.insert(nargs,v) end]]
      table.insert(EventStack,{name,...})
    end
    end)
  end
  
  hookEvent("love","update")
  hookEvent("love","keypressed")
  hookEvent("love","keyreleased")
  
  hookEvent("GPU","mousepressed") --So they are translated to the LIKO-12 screen
  hookEvent("GPU","mousemoved")
  hookEvent("GPU","mousereleased")
  hookEvent("GPU","touchpressed")
  hookEvent("GPU","touchmoved")
  hookEvent("GPU","touchreleased")
  
  --The api starts here--
  local CPU = {}
  
  function CPU.pullEvent()
    if #EventStack == 0 then
      Instant = true
      return 2 --To quit the coroutine resuming loop
    else
      local lastEvent = EventStack[1]
      local newEventStack = {}
      for k,v in ipairs(EventStack) do
        if k > 1 then table.insert(newEventStack,v) end --Remove the last event.
      end
      EventStack = newEventStack
      return true, unpack(lastEvent)
    end
  end
  
  return CPU
end