--A program to test the GUI library.

local term = require("terminal")
term.reload()

local GUIState = require("Libraries.GUI")

local MainState = GUIState(5)

local b1 = MainState:newObject("button","Button",5,5)

local trashIcon = image(
[[LK12;GPUIMG;13x13;
5999999999995
9999555559999
9555555555559
9556666666559
9956666666599
9956565656599
9956565656599
9956565656599
9956565656599
9956565656599
9956666666599
9995555555999
5999999999995]]
)

local ib1 = MainState:newObject("imageButton",5,15)
ib1:setImage(trashIcon,4,9)
--local s1 = MainState:newObject("slider", 20,20)

clear(5) cursor("normal")
MainState:redraw()

for event,a,b,c,d,e,f in pullEvent do
  
  MainState:event(event,a,b,c,d,e,f)
  
  if event == "keypressed" then
    if a == "escape" then
      break
    end
  end
  
end