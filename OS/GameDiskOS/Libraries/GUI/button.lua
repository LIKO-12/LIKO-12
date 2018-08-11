local path = select(1,...):sub(1,-(string.len("button")+1))
local class = require("Libraries.middleclass")

local base = require(path..".base")

--Button with a text label
local button = class("DiskOS.GUI.button",base)

--Default Values:
button.static.text = "Button"
button.static.align = "center"

--Callbacks
--button.onclick(button) -> Called when the button is clicked.

--Create a new button object:
--<gui> -> The GUI instance that should contain the button.
--[text] -> The text of the button label.
--[x],[y] -> The position of the top-left corner of the button.
--[align] -> The aligning of the button label text.
--[w],[h] -> The size of the button, automatically calculated by default.
function button:initialize(gui,container,text,x,y,align,w,h)
  base.initialize(self,gui,container,x,y,w,h)

  self:setAlign(align or button.static.align, true)

  self:setText(text or button.static.text, true)
end

--Set the text align in the button label (when using multiline)
function button:setAlign(align,nodraw)
  if not nodraw then self:clear() end
  
  self.align = align or self.align
  
  if not nodraw then self:draw() end
  
  return self
end

--Get the current text align
function button:getAlign() return self.align end

--Set the button text
function button:setText(t,nodraw)
  if not nodraw then self:clear() end
  
  self.text = t or self.text

  local x = self:getX()
  local cw = self.container:getWidth()

  local fw, fh = fontSize()
  local maxlen, wt = wrapText(t,cw-x)
  self:setWidth(maxlen+1,true)
  self:setHeight(#wt*(fh+1),true)

  if not nodraw then
    self:draw() --Update the button
  end

  return self
end

--Get the button text
function button:getText() return self.text end

--Draw the button
function button:draw()
  local lightcol = self:getLightColor()
  local darkcol = self:getDarkColor()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local text = self:getText()
  local down = self:isDown()

  if down then
    lightcol,darkcol = darkcol,lightcol
  end

  rect(x,y,w,h,false,lightcol)
  color(darkcol)
  print(text,x+1,y+1,w-1,self.align)
end

--Internal functions--

--Handle cursor press
function button:pressed(x,y)
  if isInRect(x,y,{self:getRect()}) then
    self:draw() --Update the button
    return true
  end
end

--Handle cursor release
function button:released(x,y)
  if isInRect(x,y,{self:getRect()}) then
    if self.onclick then
      self:onclick()
    end
  end

  self:draw() --Update the button
end

return button