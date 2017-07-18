if select(1,...) == "-?" then
  printUsage(
    "joymap","Remaps the joystick keys"
  )
  return
end

color(9) print("(enter): Skip/Leave as it is") color(7)

local bname = {"X Axis","Y Axis","Left","Right","Up","Down","A","B","Start"}

local GUID

local function getKey()
  local keysflag = {}
  for event,a,b,c in pullEvent do
    if event == "keypressed" then
      keysflag[a] = not c
    elseif event == "keyreleased" then
      if keysflag[a] then return a end
    end
  end
end

local function getGUID()
  Gamepad._GetGUID()
  for event,a,b,c,d,e,f in pullEvent do
    if event == "keypressed" then
      if a == "return" or a == "esc" then
        Gamepad._CancelMapping()
        return false
      end
    elseif event == "_gamepadmap" then
      if a then --Success
        GUID = a
        cprint("GUID: "..GUID)
        return true
      end
    end
  end
end

local function mapKey(id)
  Gamepad._MapButton(GUID,id)
  for event,a,b,c,d,e,f in pullEvent do
    if event == "keypressed" then
      if a == "return" or a == "esc" then
        Gamepad._CancelMapping()
        return false
      end
    elseif event == "_gamepadmap" then
      if a then --Success
        return true
      else
        cprint("Failed to remap !")
      end
    end
  end
end

print("Press a button from the joystick to remap")

if not getGUID() then 
  color(8) print("Joystick remapping canceled !")
  return
end

for i=1, #bname do
  if i % 2 == 0 then color(7) else color(6) end
  if i < 3 then
    print("Move "..bname[i])
  else
    print("Press "..bname[i])
  end
  mapKey(i)
end

color(9) print("Would you like to save the new joystick mapping ? (y/n)",false)
while true do
  local answer = getKey()
  if answer == "y" then
    if Gamepad._SaveMap() then
      color(11) print(" Saved")
    else
      color(8) print("\nFailed to save !")
    end
    break
  elseif answer == "n" then
    color(8) print(" Canceled")
    print('Type "reboot hard" to revert changes !')
    break
  end
end