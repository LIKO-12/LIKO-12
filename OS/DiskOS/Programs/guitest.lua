--A program to test the GUI library.

local GUIClass = require("Libraries.GUI")

local GUI = GUIClass(5)

local s1 = GUI:newObject("slider", 20,20)

clear(5)
GUI:redraw()

for event,a,b,c,d,e,f in pullEvent do
  
  GUI:event(event,a,b,c,d,e,f)
  
  if event == "keypressed" then
    if a == "escape" then
      break
    end
  end
  
end