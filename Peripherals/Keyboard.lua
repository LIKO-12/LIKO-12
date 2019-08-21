local events = require("Engine.events")

return function(config) --A function that creates a new Keyboard peripheral.

  local OSX = (love.system.getOS() == "OS X")

  if config._SpaceWalkthrough then
    events.register("love:keypressed",function(key,sc,isrepeat)
      if key == "space" then
        events.trigger("love:textinput"," ")
      end
    end)
  end

  if config._Android then
    events.register("love:textinput",function(t)
      events.trigger("love:keypressed",string.lower(t),string.lower(t))
      events.trigger("love:keyreleased",string.lower(t),string.lower(t))
    end)
  end

  if config.CPUKit then --Register Keyboard events
    local cpukit = config.CPUKit
      events.register("love:keypressed", function(k,...)
      if OSX then
        if k == "lgui" then
          cpukit.triggerEvent("keypressed","lctrl",...)
        elseif k == "rgui" then
          cpukit.triggerEvent("keypressed","rctrl",...)
        elseif love.keyboard.isDown("lalt","ralt") and k == "backspace" then
          cpukit.triggerEvent("keyreleased", "delete",...)
        end
      end
      cpukit.triggerEvent("keypressed",k,...)
    end)

    events.register("love:keyreleased", function(k,...)
      if OSX then
        if k == "lgui" then
          cpukit.triggerEvent("keyreleased","lctrl",...)
        elseif k == "rgui" then
          cpukit.triggerEvent("keyreleased","rctrl",...)
        elseif love.keyboard.isDown("lalt","ralt") and k == "backspace" then
          cpukit.triggerEvent("keyreleased", "delete",...)
        end
      end
      cpukit.triggerEvent("keyreleased",k,...)
    end)

    local gpukit = config.GPUKit

    --The hook the textinput for feltering characters not in the font
    events.register("love:textinput",function(text)
      local text_escaped = text:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
      if #text == 1 and ((not gpukit) or gpukit._FontChars:find(text_escaped)) then
        cpukit.triggerEvent("textinput",text)
      end
    end)
  end

  --The api starts here--
  local KB = {}

  function KB.textinput(state)
    if type(state) ~= "nil" then
      love.keyboard.setTextInput(state or config._EXKB)
    else
      return love.keyboard.getTextInput()
    end
  end

  function KB.keyrepeat(state)
    if type(state) ~= "nil" then
      love.keyboard.setKeyRepeat(state)
    else
      return love.keyboard.getKeyRepeat()
    end
  end

  function KB.keytoscancode(key)
    if type(key) ~= "string" then return false, "Key must be a string, provided: "..type(key) end --Error
    local ok, err = pcall(love.keyboard.getScancodeFromKey, key)
    if ok then
      return err
    else
      return error(err)
    end
  end

  function KB.scancodetokey(scancode)
    if type(scancode) ~= "string" then return false, "Scancode must be a string, provided: "..type(scancode) end --Error
    local ok, err = pcall(love.keyboard.getKeyFromScancode, scancode)
    if ok then
      return err
    else
      return error(err)
    end
  end

  function KB.isKDown(...)
    if love.keyboard.isDown(...) then
      return true
    end

    if OSX then
      local args = {...}
      for i=1, #args do
        local key = args[i]
        if key == "lctrl" and love.keyboard.isDown("lgui") then
          return true
        elseif key == "rctrl" and love.keyboard.isDown("rgui") then
          return true
        elseif key == "delete" and love.keyboard.isDown("ralt", "lalt") and love.keyboard.isDown("backspace") then
          return true
        end
      end
    end

    return false
  end

  return KB
end
