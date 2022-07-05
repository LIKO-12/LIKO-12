--The handled APIS
Handled = ...

--Make peripherals as global
for k,v in pairs(Handled) do
  _G[k] = v
end

--A useful DiskOS function
function input()
  local t = ""
  
  local fw, fh = GPU.fontSize()
  local blink = false
  local blinktimer = 0
  local blinktime = 0.5
  local function drawblink()
    local cx,cy,c = GPU.printCursor()
    GPU.rect(cx*(fw+1)+1,blink and cy*(fh+1)+1 or cy*(fh+1),fw+1,blink and fh-1 or fh+3,false,blink and 4 or c) --The blink
  end
  
  for event,a,b,c,d,e,f in CPU.pullEvent do
    if event == "textinput" then
      t = t .. a
      GPU.print(a,false)
    elseif event == "keypressed" then
      if a == "backspace" then
        blink = false; drawblink()
        if t:len() > 0 then GPU.printBackspace() end
        blink = true; drawblink()
        t = t:sub(0,-2)
      elseif a == "return" then
        blink = false; drawblink()
        return t --Return the text
      elseif a == "escape" then
        return false --User canceled text input.
      elseif a == "v" and Keyboard.isKDown("lctrl","rctrl") then
        CPU.triggerEvent("textinput",CPU.clipboard())
      end
    elseif event == "touchpressed" then
      Keyboard.textinput(true)
    elseif event == "update" then --Blink
      blinktimer = blinktimer + a
      if blinktimer > blinktime then
        blinktimer = blinktimer % blinktime
        blink = not blink
        drawblink()
      end
    end
  end
end

--Start the interpreter
CPU.sleep(1)
Keyboard.textinput(true)
GPU.print(_VERSION.." Interpreter - PoorOS V1.0")
CPU.sleep(1)
GPU.pushColor()
while true do
  GPU.color(7) GPU.print("> ",false)
  local code = input(); GPU.print("")
  if code then
    local chunk, err = loadstring(code)
    if not chunk then
      GPU.color(8) GPU.print("C-ERR: "..tostring(err))
    else
      GPU.popColor()
      local ok, err = pcall(chunk)
      GPU.pushColor()
      if not ok then
        GPU.color(8) GPU.print("R-ERR: "..tostring(err))
      else
        GPU.print("")
      end
    end
  end
end