local events = require("Engine.events")
local coreg = require("Engine.coreg")

return function(config) --A function that creates a new CPU peripheral.
  local EventStack = {}
  local Instant = false
  local sleepTimer
  
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
  hookEvent("GPU","textinput")
  
  events:register("love:update",function(dt)
    if sleepTimer then
      sleepTimer = sleepTimer-dt
      if sleepTimer <=0 then
        sleepTimer = nil
        coreg:resumeCoroutine(true)
      end
    end
  end)
  
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
  
  function CPU.clearEStack()
    EventStack = {}
    return true
  end
  
  function CPU.getHostOS()
    return true, love.system.getOS()
  end
  
  function CPU.isMobile()
    if love.system.getOS() == "Android" or love.filesystem.getOS() == "iOS" then
      return true, true
    else
      return true, false
    end
  end
  
  function CPU.clipboard()
    if text then
      love.system.setClipboardText(tostring(text))
      return true
    else
      return true,love.system.getClipboardText()
    end
  end
  
  function CPU.clearClipboard()
    love.system.setClipboardText()
    return true
  end
  
  function CPU.sleep(t)
    if type(t) ~= "number" then return false, "Time must be a number, provided: "..t end
    if t < 0 then return false, "Time must be a positive number" end
    sleepTimer = t
    return 2
  end
  
  function CPU.shutdown()
    love.event.quit()
    return 2 --I don't want the coroutine to resume while rebooting
  end
  
  function CPU.reboot(hard)
    if hard then
      love.event.quit( "restart" )
    else
      events:trigger("love:reboot") --Tell main.lua that we have to soft reboot.
    end
    return 2 --I don't want the coroutine to resume while rebooting
  end
  
  return CPU
end