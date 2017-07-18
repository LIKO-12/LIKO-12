local events = require("Engine.events")

return function(config) --A function that creates a new Gamepad peripheral.
  local GP, devkit, indirect = {}, {}, {}
  
  local CPUKit = config.CPUKit
  if not CPUKit then error("The gamepad peripheral can't work without the CPUKit passed !") end
  
  local deadzone = config.deadzone or 0.3
  local axisMemory = {}
  
  local map = {
    ["dpleft"] = 1,
    ["dpright"] = 2,
    ["dpup"] = 3,
    ["dpdown"] = 4,
    ["a"] = 5,
    ["b"] = 6,
    ["start"] = 7
  }
  
  events:register("love:joystickadded",function(joystick)
    print("Joystick Connected ! Gamepad = "..tostring(joystick:isGamepad())..", ID = "..joystick:getID()..", GUID = "..joystick:getGUID())
  end)
  
  events:register("love:gamepadpressed",function(joystick, button)
    local id = joystick:getID()
    if not map[button] then return end --The button doesn't have a binding.
    CPUKit.triggerEvent("gamepad",true,map[button],id)
  end)
  
  events:register("love:gamepadreleased",function(joystick, button)
    local id = joystick:getID()
    if not map[button] then return end --The button doesn't have a binding.
    CPUKit.triggerEvent("gamepad",false,map[button],id)
  end)
  
  events:register("love:gamepadaxis",function(joystick, axis)
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
      
      if value > 0 then --Left
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
      
      if value > 0 then --Up
        if memory[4] then CPUKit.triggerEvent("gamepad",false,4,id); memory[4] = false end
        if not memory[3] then CPUKit.triggerEvent("gamepad",true,3,id); memory[3] = true end
      else --Down
        if memory[3] then CPUKit.triggerEvent("gamepad",false,3,id); memory[3] = false end
        if not memory[4] then CPUKit.triggerEvent("gamepad",true,4,id); memory[4] = true end
      end
    end
  end)
  
  return GP, devkit, indirect
end