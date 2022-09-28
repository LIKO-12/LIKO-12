local events = require("Engine.events")
local coreg = require("Engine.coreg")

return function(config) --A function that creates a new Gamepad peripheral.
  local GP, yGP = {}, {}
  
  local CPUKit = config.CPUKit
  if not CPUKit then error("The gamepad peripheral can't work without the CPUKit passed !") end
  
  if love.filesystem.getInfo("Miscellaneous/GamepadMapping.txt","file") then
    love.joystick.loadGamepadMappings("Miscellaneous/GamepadMapping.txt")
  end
  
  local debug = config.debug
  
  local deadzone = config.deadzone or 0.49
  local axisMemory = {}
  
  local mappingState = false --Is joystick -> gamepad mapping mode active ?
  local alreadyMapped = {}
  
  local buttonsids = { "leftx","lefty","dpleft","dpright","dpup","dpdown","a","b","start" }
  
  local map = {
    ["dpleft"] = 1,
    ["dpright"] = 2,
    ["dpup"] = 3,
    ["dpdown"] = 4,
    ["a"] = 5,
    ["b"] = 6,
    ["start"] = 7
  }
  
  events.register("love:joystickadded",function(joystick)
    print("Joystick Connected ! Gamepad: "..tostring(joystick:isGamepad())..", ID: "..joystick:getID()..", GUID: "..joystick:getGUID()..", Name: "..joystick:getName())
  end)
  
  events.register("love:gamepadpressed",function(joystick, button)
    if mappingState then return end
    
    local id = joystick:getID()
    if not map[button] then return end --The button doesn't have a binding.
    CPUKit.triggerEvent("gamepad",true,map[button],id)
  end)
  
  events.register("love:gamepadreleased",function(joystick, button)
    if mappingState then return end
    
    local id = joystick:getID()
    if not map[button] then return end --The button doesn't have a binding.
    CPUKit.triggerEvent("gamepad",false,map[button],id)
  end)
  
  events.register("love:gamepadaxis",function(joystick, axis)
    if mappingState then return end
    
    local id = joystick:getID()
    
    if not axisMemory[id] then axisMemory[id] = {false,false,false,false} end
    local memory = axisMemory[id]
    
    local value = joystick:getGamepadAxis(axis)
    
    if axis == "leftx" then
      if math.abs(value) < deadzone then --Release both left and right
        if memory[1] then CPUKit.triggerEvent("gamepad",false,1,id); memory[1] = false end
        if memory[2] then CPUKit.triggerEvent("gamepad",false,2,id); memory[2] = false end
        return
      end
      
      if value < 0 then --Left
        if memory[2] then CPUKit.triggerEvent("gamepad",false,2,id); memory[2] = false end
        if not memory[1] then CPUKit.triggerEvent("gamepad",true,1,id); memory[1] = true end
      else --Right
        if memory[1] then CPUKit.triggerEvent("gamepad",false,1,id); memory[1] = false end
        if not memory[2] then CPUKit.triggerEvent("gamepad",true,2,id); memory[2] = true end
      end
      
    elseif axis == "lefty" then
      if math.abs(value) < deadzone then --Release both up and down
        if memory[3] then CPUKit.triggerEvent("gamepad",false,3,id); memory[3] = false end
        if memory[4] then CPUKit.triggerEvent("gamepad",false,4,id); memory[4] = false end
        return
      end
      
      if value < 0 then --Up
        if memory[4] then CPUKit.triggerEvent("gamepad",false,4,id); memory[4] = false end
        if not memory[3] then CPUKit.triggerEvent("gamepad",true,3,id); memory[3] = true end
      else --Down
        if memory[3] then CPUKit.triggerEvent("gamepad",false,3,id); memory[3] = false end
        if not memory[4] then CPUKit.triggerEvent("gamepad",true,4,id); memory[4] = true end
      end
    end
  end)
  
  function GP._GetGUID()
    mappingState = {mode="getGUID"}
  end
  
  function GP._MapButton(guid,bid)
    local axis = (bid < 3)
    if axis then
      mappingState = {mode="MapAxis",guid=guid,id=buttonsids[bid]}
    else
      mappingState = {mode="MapButton",guid=guid,id=buttonsids[bid]}
    end
  end
  
  function GP._CancelMapping()
    mappingState = false
  end
  
  function GP._SaveMap()
    return love.joystick.saveGamepadMappings("Miscellaneous/GamepadMapping.txt")
  end
  
  events.register("love:joystickpressed",function(joystick,button)
    if debug then print("Joystick pressed",button) end
    if not mappingState then return end
    if mappingState.mode == "getGUID" then
      mappingState = false
      CPUKit.triggerEvent("_gamepadmap",joystick:getGUID())
    elseif mappingState.mode == "MapButton" then
      local guid = joystick:getGUID()
      local bid = mappingState.id
      if not guid == mappingState.guid then return end --It's not the joystick we are mapping !
      mappingState = false
      CPUKit.triggerEvent("_gamepadmap",love.joystick.setGamepadMapping(guid,bid,"button",button))
    end
  end)
  
  events.register("love:joystickaxis",function(joystick,axis,value)
    if debug then print("Joystick axis",axis,value) end
    if not mappingState then return end
    if math.abs(value) < deadzone then return end
    if mappingState.mode == "getGUID" then
      mappingState = false
      coreg.resumeCoroutine(true,joystick:getGUID())
    elseif mappingState.mode == "MapAxis" then
      local guid = joystick:getGUID()
      local bid = mappingState.id
      if (not guid == mappingState.guid) or alreadyMapped[axis] then return end --It's not the joystick we are mapping !
      mappingState = false
      if bid == "leftx" then alreadyMapped[axis] = true else alreadyMapped = {} end
      CPUKit.triggerEvent("_gamepadmap",love.joystick.setGamepadMapping(guid,bid,"axis",axis))
    end
  end)
  
  events.register("love:joystickhat",function(joystick,hat,direction)
    if debug then print("Joystick hat",hat,direction) end
    if not mappingState then return end
    if direction == "c" or direction:len() > 1 then return end
    if mappingState.mode == "getGUID" then
      mappingState = false
      coreg.resumeCoroutine(true,joystick:getGUID())
    elseif mappingState.mode == "MapButton" then
      local guid = joystick:getGUID()
      local bid = mappingState.id
      if not guid == mappingState.guid then return end --It's not the joystick we are mapping !
      mappingState = false
      CPUKit.triggerEvent("_gamepadmap",love.joystick.setGamepadMapping(guid,bid,"hat",hat,direction))
    end
  end)
  
  return GP, yGP
end