local events = require("Engine.events")
local coreg = require("Engine.coreg")

return function(config) --A function that creates a new CPU peripheral.
  local EventStack = {}
  local Instant = false
  local RawPull = false
  local sleepTimer
  
  local devkit = {}
  
  function devkit.triggerEvent(name,...)
	if Instant then
      Instant = false coreg:resumeCoroutine(true,name,...)
    else
      table.insert(EventStack,{name,...})
      
      if RawPull then
        RawPull = false coreg:resumeCoroutine(true,name,...)
      end
    end
  end
  
  events:register("love:update", function(...) --Update event
	   devkit.triggerEvent("update",...)
  end)
  
  events:register("love:update",function(dt) --Sleep Timer
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
  
  local indirect = { --The functions that must be called via coroutine.yield
    "pullEvent", "rawPullEvent", "shutdown", "reboot", "sleep"
  }
  
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
  
  function CPU.rawPullEvent()
    RawPull = true
    return 2
  end
  
  function CPU.triggerEvent(name,...)
    if type(name) ~= "string" then
      return false, "The event name must be a string, got a "..type(name)
    end
    
    table.insert(EventStack,{name,...})
    return true
  end
  
  function CPU.clearEStack()
    EventStack = {}
    return true
  end
  
  function CPU.getHostOS()
    return true, love.system.getOS()
  end
  
  function CPU.isMobile()
    if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
      return true, true
    else
      return true, false
    end
  end
  
  function CPU.clipboard(text)
    if text then
      love.system.setClipboardText(tostring(text))
      return true
    else
      return true, love.system.getClipboardText()
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
  
  function CPU.openAppData(tar)
    local tar = tar or "/"
    if tar:sub(0,1) ~= "/" then tar = "/"..tar end
    love.system.openURL("file://"..love.filesystem.getSaveDirectory()..tar)
    return true --It ran successfully
  end
  
  --Prints to developer console.
  function CPU.cprint(...)
    print(...)
    return true --It ran successfully
  end
  
  function VPU.getFPS()
    return love.timer.getFPS()
  end
  
  devkit.indirect = indirect
  
  return CPU, devkit, indirect
end
