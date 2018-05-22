local path = select(1,...):sub(1,-(string.len("slider")+1))

local base = require(path..".base")

--A slider
local slider = class("DiskOS.GUI.slider",base)

--Default Values:
slider.static.value = 0
slider.static.width = 5
slider.static.height = 7
slider.static.length = 32
slider.static.min = 0
slider.static.max = 1

--Create a new slider object:
--<gui> -> The GUI instance that should contain the button.
--[text] -> The text of the button label.
--[x],[y] -> The position of the top-left corner of the button.
--[align] -> The aligning of the button label text.
--[w],[h] -> The size of the button, automatically calculated by default.
function slider:initialize(gui,x,y,length,vertical,min,max,w,h)
  if vertical then
    base.initialize(self,gui,x,y,h or slider.static.height,length or slider.static.length)
  else
    base.initialize(self,gui,x,y,length or slider.static.length,h or slider.static.height)
  end
  
  self.length = length or slider.static.length --The length of the slider line
  self.min = min or slider.static.min --The smallest value in the slider
  self.max = max or slider.static.max --The biggest value in the slider
  
  self.value = 0 --The current value of the slider, A fractical point in this range: [0,1].
  
  self.vertical = vertical --Defaults to be horizental
  
  if self.vertical then
    self.w, self.h = self.h, self.w --Make the slider box vertical
    self.ex, self.ey = self.x, self.y+self.length
    self.sy = self.y - self.h/2
  else
    self.ex, self.ey = self.x+self.length, self.y
    self.x = self.sx - self.w/2
  end
end

--Some position setting/getting functions should be created.

--Done
function slider:setMin(min) self.min = min or self.min; return self end
function slider:setMax(max) self.max = max or self.max; return self end

--Done
function slider:setSteps(steps,nodraw,noclear)
  if not steps then return self end
  
  if not noclear then self:clear() end
  
  self.steps = steps
  
  self.value = self.value * (self.steps - 1) + 0.5
  self.value = math.floor(self.value)/(self.steps - 1)
  
  if self:getVertical() then
    self.y = self.sy + self.value*self.length - self.h/2
  else
    self.x = self.sx + self.value*self.length - self.w/2
  end
  
  if not nodraw then self:draw() end
  
  return self
end

--Done
function slider:setValue(value,nodraw,noclear)
  if not value then return self end
  
  if not noclear then self:clear() end
  
  self.value = (value - self.min) / (self.max - self.min)
  
  self:setSteps(self.steps,true,true) --Round it into the nearest step
  
  if self:getVertical() then
    self.y = self.sy + self.value*self.length - self.h/2
  else
    self.x = self.sx + self.value*self.length - self.w/2
  end
  
  if not nodraw then self:draw() end
  
  return self
end

--Done
function slider:getMin() return self.min end
function slider:getMax() return self.max end
function slider:getSteps() return self.steps end
function slider:getValue() return self.value*(self.max-self.min) + self.min end

--Done
function slider:setLength(length,nodraw,noclear)
  if not length then return self end --Do nothing
  
  if not noclear then
    self:clear()
  end
  
  self.length = length
  
  if self:getVertical() then
    self.ey = self.sy + self.length
    self.y = self.sy + self.length*self.value - self.h/2
  else
    self.ex = self.sx + self.length
    self.x = self.sx + self.length*self.value - self.w/2
  end
  
  if not nodraw then
    self:draw()
  end
  
  return self
end

--Done
function slider:setVertical(vertical,nodraw,noclear)
  if self.vertical and (not vertical) then --The slider is no longer vertical
    if not noclear then self:clear() end
    
    self.w, self.h = self.h, self.w
    self.ex, self.ey = self.sx + self.length, self.sy
    self.x = self.sx + self.value*self.length - self.w/2
    self.y = self.sy - self.h/2
    
    if not nodraw then self:draw() end
  elseif vertical and (not self.vertical) then --The slider is no longer horizental
    if not noclear then self:clear() end
    
    self.w, self.h = self.h, self.w
    self.ex, self.ey = self.sx, self.sy + self.length
    self.x = self.sx - self.w/2
    self.y = self.sy + self.value*self.length - self.h/2
    
    if not nodraw then self:draw() end
  end
  
  return self
end

--Done
function slider:getLength() return self.length end

--Done
function slider:getVertical() return self.vertical end

--Clear the slider drawing area
function slider:clear()
  
end

--Draw the slider
function slider:draw()
  
end

return slider