--A program to test the GUI library.

local term = require("terminal")
term.reload()

local GUIState = require("Libraries.GUI")

local MainState = GUIState(5)

local topBar = MainState:newObject("container",0,0, screenWidth(),7, 9,4,9,4)

local appTitle = topBar:newObject("textbox","GUI Demo",0,0)

local closeIcon = image(
[[LK12;GPUIMG;7x7;
1111111
1A111A1
11A1A11
111A111
11A1A11
1A111A1
1111111]]
)

local terminateFlag = false

local closeButton = topBar:newObject("imageButton",-7,0)
closeButton:setImage(closeIcon,10,1)

function closeButton:onclick()
  terminateFlag = true
end

local b1 = MainState:newObject("button","Button",5,25)

local redrawButton = MainState:newObject("button","Redraw",5,15)
function redrawButton:onclick()
  self:getGUI():draw()
end

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

local ib1 = MainState:newObject("imageButton",5,35)
ib1:setImage(trashIcon,4,9)

local horizentalSliderTextbox = MainState:newObject("textbox","HS: 0/100",55,25):setBGColor(6)
local verticalSliderTextbox = MainState:newObject("textbox","VS: 0/100",55,35):setBGColor(6)

local horizentalSlider = MainState:newObject("slider", 55,15, 32,false)
local verticalSlider = MainState:newObject("slider", 45,15, 32,true)

function horizentalSlider:onchange()
  horizentalSliderTextbox:setText("HS: "..math.floor(self:getValue(0,100)).."/100")
end

function verticalSlider:onchange()
  verticalSliderTextbox:setText("VS: "..math.floor(self:getValue(0,100)).."/100")
end

local mousePosTextbox = MainState:newObject("textbox",string.format("MX: %d MY: %d",getMPos()),1,0)
mousePosTextbox:setY(-1):setBGColor(6)

cursor("normal")
MainState:draw()
--c1:draw()

for event,a,b,c,d,e,f in pullEvent do
  
  MainState:event(event,a,b,c,d,e,f)
  
  if terminateFlag then break end
  
  if event == "keypressed" then
    if a == "escape" then
      break
    end
  elseif event == "mousemoved" then
    mousePosTextbox:setText(string.format("MX: %d MY: %d",a,b))
  end
  
end