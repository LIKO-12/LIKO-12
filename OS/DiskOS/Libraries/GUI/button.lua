local path = select(1,...):sub(1,-(string.len("button")+1))

local base = require(path..".base")

--Wrap a function, used to add functions alias names.
local function wrap(f)
  return function(self,...)
    local args = {pcall(self[f],self,...)}
    if args[1] then
      return select(2,unpack(args))
    else
      return error(tostring(args[2]))
    end
  end
end

--Button with a text label
local button = class("DiskOS.GUI.button",base)

--Default Values:
button.static.text = "Button"   
button.static.align = "center"

function button:initialize(gui,text,x,y,align,w,h)
  base.initialize(self,gui,x,y,w,h)
  
  self:setAlign(align or button.static.align, true)
  
  self:setText(text or button.static.text,true)
end

--Set the text align in the button label (when using multiline)
function button:setAlign(align,nodraw)
  self.align = align or self.align
  if not nodraw then self:draw() end
  return self
end

--Get the current text align
function button:getAlign() return self.align end

--Set the button text
function button:setText(t,nodraw)
  self.text = t or self.text
  
  local x = self:getX()
  local gw = self.gui:getWidth()
  
  local fw = self.gui:getFontWidth()
  local fh = self.gui:getFontHeight()
  local maxlen, wt = wrapText(t,gw-x)
  self:setWidth(maxlen+1,true)
  self:setHeight(#wt*(fh+2),true)
  
  if not nodraw then
    self:draw() --Update the button
  end
  
  return self
end

--Get the button text
function button:getText() return self.text end

--Draw the button
function button:draw()
  local fgcol = self:getFGColor()
  local bgcol = self:getBGColor()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local text = self:getText()
  local down = self:isDown()
  
  if down then
    fgcol,bgcol = bgcol,fgcol
  end
  
  rect(x,y,w,h,false,fgcol)
  color(bgcol)
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

--Provide prefered cursor
function button:cursor(x,y)
  local down = self:isDown()
  
  if isInRect(x,y,{self:getRect()}) then
    if down then
      return "handpress"
    else
      return "handrelease"
    end
  end
end

return button