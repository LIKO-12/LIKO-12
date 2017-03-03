local events = require("Engine.events")

return function(config) --A function that creates a new Keyboard peripheral.
  
  if config._SpaceWalkthrough then
    events.register("love:keypressed",function(key,sc,isrepeat)
      if key == "space" then
        events:trigger("love:textinput"," ")
      end
    end)
  end
  
  --The api starts here--
  local KB = {}
  
  function KB.textinput(state)
    if type(state) ~= "nil" then
      love.keyboard.setTextInput(state)
      return true
    else
      return true, love.keyboard.getTextInput()
    end
  end
  
  function KB.keyrepeat(state)
    if type(state) ~= "nil" then
      love.keyboard.setKeyRepeat(state)
      return true
    else
      return true, love.keyboard.getKeyRepeat()
    end
  end
  
  function KB.keytoscancode(key)
    if type(key) ~= "string" then return false, "Key must be a string, provided: "..type(key) end --Error
    return pcall(love.keyboard.getScancodeFromKey, key)
  end
  
  function KB.scancodetokey(scancode)
    if type(scancode) ~= "string" then return false, "Scancode must be a string, provided: "..type(scancode) end --Error
    return pcall(love.keyboard.getKeyFromScancode, key)
  end
  
  function KB.isKDown(...)
    return true, love.keyboard.isDown(...)
  end
  
  return KB
end