--Text Utilities.

--Variables.
local fw, fh = fontSize() --The LIKO-12 GPU Font size.

--Localized Lua Library


--The API
local TextUtils = {}

function TextUtils.textInput(historyTable,preinput)
  local history = historyTable or {} --The history of commands.
  local hispos --The current item in the history.
  local btimer, btime, blink = 0, 0.5, true  --The terminal cursor blink timer.
  local buffer = preinput or "" --The terminal input buffer
  local inputPos = #buffer+1 --The next input character position in the terminal buffer.
  
  print(buffer,false)
  
  --Checks if the cursor is in the bounds of the screen.
  local function checkCursor()
    local cx, cy = printCursor()
    local tw, th = termSize()
    if cx > tw then cx = tw end
    if cx < 0 then cx = 0 end
    if cy > th then cy = th end
    if cy < 0 then cy = 0 end
    printCursor(cx,cy,0)
    rect(cx*(fw+1)+1,blink and cy*(fh+1)+1 or cy*(fh+1),fw+1,blink and fh-1 or fh+2,false,blink and 4 or 0) --The blink
    if inputPos <= buffer:len() then
      printCursor(cx,cy,-1)
      print(buffer:sub(inputPos,inputPos),false)
      printCursor(cx,cy,0)
    end
  end
  
  clearEStack()
  checkCursor()
  
  for event, a,b,c,d,e,f in pullEvent do
    checkCursor() --Which also draws the cursor blink
    
    if event == "textinput" then
      print(a..buffer:sub(inputPos,-1),false)
      for i=inputPos,buffer:len() do printBackspace(-1) end
      buffer = buffer:sub(1,inputPos-1)..a..buffer:sub(inputPos,-1)
      inputPos = inputPos + a:len()
    elseif event == "keypressed" then
      if a == "return" then
        if hispos then table.remove(history,#history) hispos = false end
        table.insert(history, buffer)
        blink = false; checkCursor()
        return buffer
      elseif a == "backspace" then
        blink = false; checkCursor()
        if buffer:len() > 0 then
          --Remove the character
          printBackspace()
          
          --Re print the buffer
          for char in string.gmatch(buffer:sub(inputPos,-1),".") do
            print(char,false)
          end
          
          --Erase the last character
          print("-",false) printBackspace()
          
          --Go back to the input position
          for i=#buffer,inputPos,-1 do
            printBackspace(-1)
          end
          
          --Remove the character from the buffer
          buffer = buffer:sub(1,inputPos-2) .. buffer:sub(inputPos,-1)
          
          --Update input postion
          inputPos = inputPos-1
        end
        blink = true; checkCursor()
      elseif a == "delete" then
        blink = false; checkCursor()
        print(buffer:sub(inputPos,-1),false)
        for i=1,buffer:len() do
          printBackspace()
        end
        buffer, inputPos = "", 1
        blink = true; checkCursor()
      elseif a == "escape" then
        blink = false checkCursor() return false
      elseif a == "up" then
        if not hispos then
          table.insert(history,buffer)
          hispos = #history
        end

        if hispos > 1 then
          hispos = hispos-1
          blink = false; checkCursor()
          print(buffer:sub(inputPos,-1),false)
          for i=1,buffer:len() do
            printBackspace()
          end
          buffer = history[hispos]
          inputPos = buffer:len() + 1
          for char in string.gmatch(buffer,".") do
            print(char,false)
          end
          blink = true; checkCursor()
        end
      elseif a == "down" then
        if hispos and hispos < #history then
          hispos = hispos+1
          blink = false; checkCursor()
          print(buffer:sub(inputPos,-1),false)
          for i=1,buffer:len() do
            printBackspace()
          end
          buffer = history[hispos]
          inputPos = buffer:len() + 1
          for char in string.gmatch(buffer,".") do
            print(char,false)
          end
          if hispos == #history then table.remove(history,#history) hispos = false end
          blink = true; checkCursor()
        end
      elseif a == "left" then
        blink = false; checkCursor()
        if inputPos > 1 then
          inputPos = inputPos - 1
          printBackspace(-1)
        end
        blink = true; checkCursor()
      elseif a == "right" then
        blink = false; checkCursor()
        if inputPos <= buffer:len() then
          print(buffer:sub(inputPos,inputPos),false)
          inputPos = inputPos + 1
        end
        blink = true; checkCursor()
      elseif a == "c" then
        if isKDown("lctrl","rctrl") then
          clipboard(buffer)
        end
      elseif a == "v" then
        if isKDown("lctrl","rctrl") then
          local paste = clipboard() or ""

          for char in string.gmatch(paste..buffer:sub(inputPos,-1),".") do
            print(char,false)
          end

          for i=inputPos,buffer:len() do printBackspace(-1) end

          buffer = buffer:sub(1,inputPos-1)..paste..buffer:sub(inputPos,-1)
          inputPos = inputPos + paste:len()
        end
      end
    elseif event == "touchpressed" then
      textinput(true)
    elseif event == "update" then
      btimer = btimer + a
      if btimer > btime then
        btimer = btimer%btime
        blink = not blink
      end
    end
  end
end

--Make the textutils a global
_G["TextUtils"] = TextUtils