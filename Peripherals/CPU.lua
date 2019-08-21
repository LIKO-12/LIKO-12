local events = require("Engine.events")
local coreg = require("Engine.coreg")

return function(config) --A function that creates a new CPU peripheral.
  local EventStack = {}
  local Instant = false
  local RawPull = false
  local sleepTimer
  
  local devkit = {}
  
  function devkit.triggerEvent(name,...)
    if Instant or RawPull then
      Instant, RawPull = false, false
      coreg.resumeCoroutine(true,name,...)
    else
      table.insert(EventStack,{name,...})
      end
  end
  
  events.register("love:update", function(...) --Update event
    if not sleepTimer then devkit.triggerEvent("update",...) end
  end)
  
  events.register("love:update",function(dt) --Sleep Timer
    if sleepTimer then
      sleepTimer = sleepTimer-dt
      if sleepTimer <=0 then
        sleepTimer = nil
        coreg.resumeCoroutine(true)
      end
    end
  end)

  local function Verify(value,name,etype,allowNil)
    if type(value) ~= etype then
      if allowNil then
        error(name.." should be a "..etype.." or a nil, provided: "..type(value),3)
      else
        error(name.." should be a "..etype..", provided: "..type(value),3)
      end
    end
    
    if etype == "number" then
      return math.floor(value)
    end
  end
  
  --The api starts here--
  local CPU, yCPU = {}, {}
  
  function yCPU.pullEvent()
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
  
  function yCPU.rawPullEvent()
    RawPull = true
    return 2
  end
  
  function CPU.triggerEvent(name,...)
    Verify(name,"The event name","string")
    table.insert(EventStack,{name,...})
  end
  
  function CPU.clearEStack()
    EventStack = {}
  end
  
  function CPU.getHostOS()
    return love.system.getOS()
  end
  
  function CPU.isMobile()
    return (love.system.getOS() == "Android" or love.system.getOS() == "iOS")
  end
  
  function CPU.clipboard(text)
    if text then
      love.system.setClipboardText(tostring(text))
    else
      return love.system.getClipboardText()
    end
  end
  
  function CPU.clearClipboard()
    love.system.setClipboardText()
  end
  
  function yCPU.sleep(t)
    if type(t) ~= "number" then return false, "Time must be a number, provided: "..t end
    if t < 0 then return false, "Time must be a positive number" end
    sleepTimer = t
    return 2
  end
  
  function yCPU.shutdown()
    love.event.quit()
    return 2 --I don't want the coroutine to resume while rebooting
  end
  
  function yCPU.reboot(hard)
    if hard then
      love.event.quit( "restart" )
    else
      events.trigger("love:reboot") --Tell main.lua that we have to soft reboot.
    end
    return 2 --I don't want the coroutine to resume while rebooting
  end
  
  function CPU.openURL(url)
    Verify(url,"URL","string")
    love.system.openURL(url)
  end
  
  function CPU.openAppData(tar)
    tar = tar or "/"
    if tar:sub(1,1) ~= "/" then tar = "/"..tar end
    if tar:sub(-1,-1) ~= "/" then tar = tar.."/" end
    love.system.openURL("file://"..love.filesystem.getSaveDirectory()..tar)
  end
  
  function CPU.getSaveDirectory()
    return love.filesystem.getSaveDirectory()
  end
  
  --Prints to developer console.
  function CPU.cprint(...)
    print(...)
  end
  
  CPU.getFPS = love.timer.getFPS
  
  devkit.CPU = CPU
  devkit.yCPU = yCPU
  
  return CPU, yCPU, devkit
end
