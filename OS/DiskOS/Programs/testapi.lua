--This is a program for testing LIKO-12 API.
local sw, sh = screenSize()
local tw, th = termSize()

--Wait for any keypress or screen touch.
local function waitrelease()
  for event in pullEvent do
    if event == "keyreleased" then return end
  end
end

local function wait()
  for event,a in pullEvent do
    if event == "keypressed" then waitrelease() return a == "escape" end
    if event == "touchpressed" then return end
  end
end

local events

--Reset the events system
local function reset()
  events = {}
  events.touchpressed = function() textinput(true) end
end

--Start the events loop
local function loop()
  for event, a,b,c,d,e,f in pullEvent do
    if events[event] then
      if events[event](a,b,c,d,e,f,g,h) then break end
    end
    if event == "keypressed" then
      if a == "escape" then
        waitrelease()
        return true
      elseif a == "return" then
        return
      end
    end
  end
end

local tests = {}

local function add(func) table.insert(tests,func) end

-----------------------------------------------------------------------------------------
--==Intro==--
local function _intro()
  print("This is a program for testing LIKO-12 api functionality")
end
add(_intro)

--==Formatted Print==--
local function _fprint()
  print("This is a formatted print, the text should wrap, and the background shouldn't be drawn automatically.\n this is a new line.\r this is a carraige return.\nPress any key to change the align.",0,0,sw,"left")
  if wait() then return true end
  clear()
  print("This is a formatted print, the text should wrap, and the background shouldn't be drawn automatically.\n this is a new line.\r this is a carraige return.\nPress any key to change the align.",0,0,sw,"center")
  if wait() then return true end
  clear()
  print("This is a formatted print, the text should wrap, and the background shouldn't be drawn automatically.\n this is a new line.\r this is a carraige return.",0,0,sw,"right")
end
add(_fprint)

--==Formatted Print Type Writer Effect==--
local function _fprinttw()
  local text = "This is a type writer effect used to test formatted print responds, also here's a \n newline, and here's a \r carraige return, blah blah blah."
  local len = text:len()
  local pos = 1
  local align = "left"
  
  reset()
  function events.update(dt)
    -- Update
    pos = pos + dt*10
    
    -- Draw
    clear()
    print(text:sub(1,math.floor(pos)),0,0,sw,align)
    
    if math.floor(pos) > len then return true end
  end
  if loop() then return end
  
  pos, align = 1, "center"
  if loop() then return end
  
  pos, align = 1, "right"
  if loop() then return end
end
add(_fprinttw)

--==Normal Printing==--
local function _nprint()
  print("Normal printing, this text must flow out of the screen very easily",0,0,false)
end
add(_nprint)

--==Terminal Printing==--
local function _tprint()
  color(0)
  printCursor(false,false,7)
  print("This is terminal printing, the text here must wrap automatically and have a white background fill, the text is also black, and this is a \n new line, and this is a \r carraige return, blah blah blah blah blah blah blah !@#$@^$@#^&@^@#$@^&*()_&$")
  print("This is another print")
  print("This is a careless print",false,true)
end
add(_tprint)

--====--
--[[local function _()
  
end
add(_)]]

-----------------------------------------------------------------------------------------

for id, test in ipairs(tests) do
  clear() --Clear the screen
  pal() palt() --Reset the palettes
  cam() --Reset the camera
  printCursor(0,0,0) --Reset the print cursor
  color(7) --Set the color to white
  
  if test() then return end
  printCursor(tw-1,th-2,0)
  color(9) print("[Press any key to continue]",false)
  if wait() then return end
end