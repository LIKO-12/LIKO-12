--Base object class
local base = class("DiskOS.GUI.base")

--Create a new object base:
--<gui>: The GUI instance that should contain the object.
--[x],[y]: The position of the top-left corner of the object.
--[w],[h]: The size of the object.
function base:initialize(gui,x,y,w,h)
  self.gui = gui or error("GUI State has to be passed",2)
  
  self.x, self.y = 0, 0
  self.w, self.h = 0, 0
  
  --self.touchid -> The object press touch id.
  --self.mousepress -> True when the object is pressed using the mouse.
  --self.down -> Is the object being held down ?
  
  self:setSize(w,h,true)
  self:setPosition(x,y,true)
  
  self:setLightColor(self.gui:getLightColor(),true)
  self:setDarkColor(self.gui:getDarkColor(),true)
  self:setBGColor(self.gui:getBGColor(),true)
  self:setTColor(self.gui:getTColor(),true)
end

--Get object GUI instance.
function base:getGUI()
  return self.gui
end

--Set object position, accepts negative positions (GUI size - pos).
function base:setX(x,nodraw)
  if x then
    if x < 0 then
      x = self.gui:getWidth()-self.w+x
    end
  end
  
  self.x = x or self.x
  if not nodraw then self:draw() end
  
  return self
end

function base:setY(y,nodraw)
  if y then
    if y < 0 then
      y = self.gui:getHeight()-self.h+y
    end
  end
  
  self.y = y or self.y
  if not nodraw then self:draw() end
  
  return self
end

function base:setPos(x,y,nodraw)
  self:setX(x,true)
  self:setY(y,true)
  
  if not nodraw then self:draw() end
  
  return self
end
base.setPosition = base.setPos

--Get object position
function base:getX() return self.x end
function base:getY() return self.y end
function base:getPos() return self:getX(), self:getY() end
base.getPosition = base.getPos

--Set object size
function base:setWidth(w,nodraw)
  self.w = w or self.w
  if not nodraw then self:draw() end
  
  return self
end

function base:setHeight(h,nodraw)
  self.h = h or self.h
  if not nodraw then self:draw() end
  
  return self
end

function base:setSize(w,h,nodraw)
  self:setWidth(w,true)
  self:setHeight(h,true)
  
  if not nodraw then self:draw() end
  
  return self
end

--Get object size
function base:getWidth() return self.w end
function base:getHeight() return self.h end
function base:getSize() return self:getWidth(), self:getHeight() end

function base:setRect(x,y,w,h,nodraw)
  self:setPosition(x,y,true)
  self:setSize(x,y,true)
  
  if not nodraw then self:draw() end
  
  return self
end

function base:getRect()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  return x,y,w,h
end

--Set object colors
function base:setLightColor(lightcol,nodraw)
  self.lightcol = lightcol or self.lightcol
  if not nodraw then self:draw() end
  return self
end

function base:setDarkColor(darkcol,nodraw)
  self.darkcol = darkcol or self.darkcol
  if not nodraw then self:draw() end
  return self
end

function base:setBGColor(bgcol,nodraw)
  self.bgcol = bgcol or self.bgcol
  if not nodraw then self:draw() end
  return self
end

function base:setTColor(tcol,nodraw)
  self.tcol = tcol or self.tcol
  if not nodraw then self:draw() end
  return self
end

function base:setColors(lightcol,darkcol,bgcol,tcol,nodraw)
 self:setLightColor(lightcol,true)
 self:setDarkColor(darkcol,true)
 self:setBGColor(bgcol,true)
 self:setTColor(tcol,true)
 
 if not nodraw then self:draw() end
 
 return self
end

--Get object colors
function base:getLightColor() return self.lightcol end
function base:getDarkColor() return self.darkcol end
function base:getBGColor() return self.bgcol end
function base:getTColor() return self.tcol end
function base:getColors() return self:getLightColor(), self:getDarkColor(), self:getBGColor(), self:getTColor() end

--Set the object sheet
function base:setSheet(sheet,nodraw)
  self.sheet = sheet or self.sheet
  if not nodraw then self:draw() end
  return self
end

--Get the object sheet
function base:getSheet() return self.sheet end

--Is the object being held down.
function base:isDown() return self.down end

--Has to be overwritten
function base:_update(dt) end
function base:draw(dt) end
function base:pressed(x,y) return false end --Called when the mouse/touch is pressed.
function base:released(x,y) end --Called when the mouse/touch is released after returning try from base:pressed.
function base:cursor(x,y) end --Should return prefered cursor name.

--Internal functions to handle multitouch and computer mouse
function base:_mousepressed(x,y,b,istouch)
  if self.down or istouch then return end
  self.mousepress = true
  self.down = true
  self.mousepress = self:pressed(x,y,b)
  self.down = self.mousepress
  return self.mousepress
end

function base:_mousereleased(x,y,b,istouch)
  if self.touchid or (not self.mousepress) or istouch then return end
  self.down = false
  self:released(x,y)
  self.mousepressed = false
  return true
end

function base:_touchpressed(id,x,y)
  if self.down then return end
  self.touchid = id
  self.down = true
  if not self:pressed(x,y) then
    self.touchid = nil
    self.down = false
  end
  return self.touchid
end

function base:_touchreleased(id,x,y)
  if (not self.touchid) or self.mousepress then return end
  if self.touchid ~= id then return end
  self.down = false
  self:released(x,y)
  self.touchid = nil
  return true
end

return base