local path = select(1,...):sub(1,-(string.len("scrollbar")+1))
local class = require("Libraries.middleclass")

local base = require(path..".base")
local container = require(path..".container")

local onMobile = isMobile()

--Internal images
local imgdataCheckboard = imagedata("LK12;GPUIMG;2x2;1001;")
local imgArrowUp = image("LK12;GPUIMG;8x8;7777777777777777777667777766667776666667766666677777777707777770;")
local imgArrowDown = image("LK12;GPUIMG;8x8;0777777077777777766666677666666777666677777667777777777777777777;")
local imgBodyCap = image("LK12;GPUIMG;8x2;0066660006777760;")

--Internal objects
local scrollBody = class("DiskOS.GUI.scrollbar.body",base)

function scrollBody:draw()
  local lightcol = self:getLightColor()
  local darkcol = self:getDarkColor()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local down = self:isDown()

  if down then
    lightcol,darkcol = darkcol,lightcol
  end
  
  rect(x,y+2,w,h-4,false,lightcol)
  line(x,y+1,x,y+h-2-1, darkcol)
  line(x+w-1,y+1,x+w-1,y+h-2-1, darkcol)
  
  pushPalette()
  pal(6,darkcol) pal(7,lightcol)
  imgBodyCap:draw(x,y)
  imgBodyCap:draw(x,y+h,0,1,-1)
  popPalette()
  --rect(x,y,w,h,true,darkcol)
end

function scrollBody:pressed(x,y)
  if isInRect(x,y,{self:getRect()}) then
    self:draw() --Update the button
    return true
  end
end

function scrollBody:released(x,y)
  self:draw()
end

--Scrollbar
local scrollbar = class("DiskOS.GUI.scrollbar",container)

--Default Values:
--scrollbar.static.

--Callbacks
--scrollbar.onchange(scrollbar) -> Called when the scrollbar is moved.

--Create a new scrollbar object:
--<gui> -> The GUI instance that should contain the button.
--[x],[y] -> The position of the top-left corner of the button.
function scrollbar:initialize(gui,parentContainer,x,y,length,horizental)
  local w,h; if horizental then w,h = length, 8 else w,h = 8,length end
  container.initialize(self,gui,parentContainer,x,y,w,h)
  
  self:setBGColor(0,true)
  self:setTColor(6,true)
  
  self.upButton = self:newObject("imageButton",0,0):setImage(imgArrowUp,6,7,true)
  self.downButton = self:newObject("imageButton",0,0):setImage(imgArrowDown,6,7,true)
  
  if horizental then
    self.downButton:setPosition(w-8,0)
    self.body = scrollBody(gui,self,8,0, w-16,8)
  else
    self.downButton:setPosition(0,h-8)
    self.body = scrollBody(gui,self,0,8, 8,h-16)
  end
  
  
  self:register(self.body)
end

--Draw the scrollbar background
function scrollbar:_draw(dt)
  if self:isVisible() then
    local x,y = self:getPosition()
    local w,h = self:getSize()
    local bgColor = self:getBGColor()
    local tColor = self:getTColor()
    rect(x,y,w,h,false,bgColor)
    
    patternFill(imgdataCheckboard)
    rect(x+1,y+9,w-2,h-18,false,tColor)
    patternFill()
    
    self:event("draw")
  end
end

return scrollbar