local path = select(1,...):sub(1,-(string.len("textbox")+1))
local class = require("Libraries.middleclass")

local base = require(path..".base")

--Button with a text label
local textbox = class("DiskOS.GUI.textbox",base)

--Default Values:
textbox.static.text = "Text"
textbox.static.align = "left"

--Create a new text object:
--<gui> -> The GUI instance that should contain the button.
--[text] -> The text.
--[x],[y] -> The position of the top-left corner of the textbox.
--[align] -> The aligning of the text in the textbox.
--[w],[h] -> The size of the textbox, automatically calculated by default.
function textbox:initialize(gui,container,text,x,y,align,w,h)
  base.initialize(self,gui,container,x,y,w,h)

  self:setAlign(align or textbox.static.align, true)

  self:setText(text or textbox.static.text, true)
end

--Set the text align in the button label (when using multiline)
function textbox:setAlign(align,nodraw)
  if not nodraw then self:clear() end
  
  self.align = align or self.align
  
  if not nodraw then self:draw() end
  
  return self
end

--Get the current text align
function textbox:getAlign() return self.align end

--Set the button text
function textbox:setText(t,nodraw)
  if not nodraw then self:clear() end
  
  self.text = t or self.text
  
  local w,h = self:getSize()

  local x = self:getX()
  local cw = self.container:getWidth()

  local fw fh = fontSize()
  local maxlen, wt = wrapText(t,cw-x)
  
  self:setWidth(maxlen+1,true)
  self:setHeight(#wt*(fh+1)+1,true)

  if not nodraw then
    self:draw() --Update the button
  end

  return self
end

--Get the button text
function textbox:getText() return self.text end

--Draw the button
function textbox:draw()
  local tcol = self:getTColor()
  local bgcol = self:getBGColor()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local text = self:getText()

  rect(x,y,w,h,false,bgcol)
  color(tcol)
  print(text,x+1,y+1,w-1,self.align)
end

--Override cursor() so it doesn't change the cursor to a handshape.
function textbox:cursor() end

return textbox