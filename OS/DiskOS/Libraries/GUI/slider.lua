local path = select(1,...):sub(1,-(string.len("slider")+1))

local base = require(path..".base")

--Button with a text label
local slider = class("DiskOS.GUI.slider",base)

--Default Values:
slider.static.length = 32
slider.static.min = 0
slider.static.max = 1
slider.static.value = 0
slider.static.w = 3
slider.static.h = 7

--Callbacks
--slider.onchange(slider) -> Called when the slide is moved.

--Create a new button object:
--<gui> -> The GUI instance that should contain the button.
--[text] -> The text of the button label.
--[x],[y] -> The position of the top-left corner of the button.
--[align] -> The aligning of the button label text.
--[w],[h] -> The size of the button, automatically calculated by default.
function slider:initialize(gui,container,x,y,length,vertical,max,min,w,h)
  if vertical then
    base.initialize(self,gui,container,x,y,h or slider.static.h,w or slider.static.w)
  else
    base.initialize(self,gui,container,x,y,w or slider.static.w,h or slider.static.h)
  end
  
  self.vertical = vertical
  
  self:setValue(slider.static.value, slider.static.min, slider.static.max, true)
  self:setLength(length or slider.static.length, true)
end

function slider:setValue(v,min,max,nodraw)
  if not nodraw then self:clear() end
  self.value = math.min(math.max(v or self.value,min),max)
  if not nodraw then self:draw() end
  
  return self
end

function slider:getValue(min,max)
  return self.value
end

function slider:setLength(l,nodraw)
  if not nodraw then self:clear() end
  self.length = l or self.length
  if not nodraw then self:draw() end
  
  return self
end

function slider:getLength()
  return self.length
end

function slider:setOrientation(vertical,nodraw)
  if (self.vertical and vertical) or not (self.vertical or vertical) then return end --Not changed
  
  if not nodraw then self:clear() end
  
  self.vertical = vertical
  
  --Swap the width and height
  local w,h = self:getSize()
  self:setSize(h,w)
  
  if not nodraw then self:draw() end
  
  return self
end

function slider:getOrientation()
  return self.vertical
end

function slider:getHandlePosition()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local length = self:getLength()
  local value = self:getValue(0,1)
  local vertical = self:getOrientation()
  
  if vertical then
    return x,y + (length-h)*value
  else
    return x + (length-w)*value,y
  end
end

function slider:clear()
  local bgcol = self.container:getBGColor()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local value = self:getValue(0,1)
  local length = self:getLength()
  local vertical = self:getOrientation()
  
  if vertical then
    rect(x,y,w,length,false,bgcol)
  else
    rect(x,y,length,h,false,bgcol)
  end
end

function slider:draw()
  local lightcol = self:getLightColor()
  local darkcol = self:getDarkColor()
  local tcol = self:getTColor()
  local x,y = self:getPosition()
  local hx,hy = self:getHandlePosition()
  local w,h = self:getSize()
  local value = self:getValue(0,1)
  local length = self:getLength()
  local vertical = self:getOrientation()
  local down = self:isDown()
  
  if down then
    lightcol,darkcol = darkcol,lightcol
  end
  
  if vertical then
    line(x+w/2-1,y+1, x+w/2-1,y+length-2, tcol)
  else
    line(x+1,y+h/2-1, x+length-2,y+h/2-1, tcol)
  end
  
  rect(hx,hy,w,h,false,lightcol)
end

--Internal functions--

--Handle cursor press
function slider:pressed(x,y)
  local hx,hy = self:getHandlePosition()
  local w,h = self:getSize()
  if isInRect(x,y,{hx,hy,w,h}) then
    self:draw() --Update the button
    return true
  end
end

function slider:dragged(x,y,dx,dy)
  local vertical = self:getOrientation()
  local bx, by = self:getPosition()
  local w,h = self:getSize()
  local length = self:getLength()
  
  if vertical then
    self:setValue((y-by)/(length-h),0,1)
  else
    self:setValue((x-bx)/(length-w),0,1)
  end
end

--Handle cursor release
function slider:released(x,y)
  local hx,hy = self:getHandlePosition()
  local w,h = self:getSize()
  if isInRect(x,y,{hx,hy,w,h}) then
    --[[if self.onclick then
      self:onclick()
    end]]
  end

  self:draw() --Update the button
end

--Provide prefered cursor
function slider:cursor(x,y)
  local down = self:isDown()

  if down then
    return "handpress"
  else
    local hx,hy = self:getHandlePosition()
    local w,h = self:getSize()
    if isInRect(x,y,{hx,hy,w,h}) then
      return "handrelease"
    end
  end
end

return slider