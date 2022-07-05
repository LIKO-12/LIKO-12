local class = require("Libraries.middleclass")

--Base object class
local base = class("DiskOS.GUI.base")

--Create a new object base:
--<gui>: The GUI instance that should contain the object.
--[x],[y]: The position of the top-left corner of the object.
--[w],[h]: The size of the object.
function base:initialize(gui,container,x,y,w,h)
  self.gui = gui or error("GUI State has to be passed",2)
  self.container = container or error("Container has to be passed",2)

  self.x, self.y = 0, 0
  self.w, self.h = 0, 0
  self.visible = true

  --self.touchid -> The object press touch id.
  --self.mousepress -> True when the object is pressed using the mouse.
  --self.down -> Is the object being held down ?

  self:setSize(w,h,true)
  self:setPosition(x,y,true)

  self:setLightColor(self.container:getLightColor(),true)
  self:setDarkColor(self.container:getDarkColor(),true)
  self:setBGColor(self.container:getBGColor(),true)
  self:setTColor(self.container:getTColor(),true)

  self:setSheet(self.container:getSheet(),true)
end

--Get object GUI instance.
function base:getGUI()
  return self.gui
end

--Get object parent container.
function base:getContainer()
  return self.container
end

--Set object visiblilty
function base:setVisible(visible,nodraw)
  self.visible = visible or false

  if not self.visible then
    self.down, self.touchid, self.mousepressed = false, false, false
    if not nodraw then self:clear() end
  end
end

function base:isVisible()
  return self.visible
end

--Set object position, accepts negative positions (GUI size - pos).
function base:setX(x,nodraw)
  if not nodraw then self:clear() end

  if x then
    if x < 0 then
      x = self.container:getWidth()-self.w+x
    end
  end

  self.x = (x or self.x) % self.container:getWidth()
  if not nodraw then self:draw() end

  return self
end

function base:setY(y,nodraw)
  if not nodraw then self:clear() end

  if y then
    if y < 0 then
      y = self.container:getHeight()-self.h+y
    end
  end

  self.y = (y or self.y) % self.container:getHeight()
  if not nodraw then self:draw() end

  return self
end

function base:setPosition(x,y,nodraw)
  if not nodraw then self:clear() end

  self:setX(x,true)
  self:setY(y,true)

  if not nodraw then self:draw() end

  return self
end

--Get object position
function base:getX() return self.x end
function base:getY() return self.y end
function base:getPosition() return self:getX(), self:getY() end

--Set object size
function base:setWidth(w,nodraw)
  if not nodraw then self:clear() end
  self.w = w or self.w
  if not nodraw then self:draw() end

  return self
end

function base:setHeight(h,nodraw)
  if not nodraw then self:clear() end
  self.h = h or self.h
  if not nodraw then self:draw() end

  return self
end

function base:setSize(w,h,nodraw)
  if not nodraw then self:clear() end

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
  if not nodraw then self:clear() end

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
  if not nodraw then self:clear() end
  self.lightcol = lightcol or self.lightcol
  if not nodraw then self:draw() end
  return self
end

function base:setDarkColor(darkcol,nodraw)
  if not nodraw then self:clear() end
  self.darkcol = darkcol or self.darkcol
  if not nodraw then self:draw() end
  return self
end

function base:setBGColor(bgcol,nodraw)
  if not nodraw then self:clear() end
  self.bgcol = bgcol or self.bgcol
  if not nodraw then self:draw() end
  return self
end

function base:setTColor(tcol,nodraw)
  if not nodraw then self:clear() end
  self.tcol = tcol or self.tcol
  if not nodraw then self:draw() end
  return self
end

function base:setColors(lightcol,darkcol,bgcol,tcol,nodraw)
  if not nodraw then self:clear() end

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
  if not nodraw then self:clear() end
  self.sheet = sheet or self.sheet
  if not nodraw then self:draw() end
  return self
end

--Get the object sheet
function base:getSheet() return self.sheet end

--Is the object being held down.
function base:isDown() return self.down end

--Provide prefered cursor
function base:cursor(x,y)
  local down = self:isDown()

  if isInRect(x,y,{self:getRect()}) then
    if down then
      return "handpress"
    elseif not (isMDown(1) or isMDown(2) or isMDown(3)) then
      return "handrelease"
    end
  end
end

--Clear previous draw area.
function base:clear()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local bgColor = self.container:getBGColor()
  rect(x,y,w,h,false,bgColor)
end

--Draw the object
function base:_draw(dt)
  if self:isVisible() then
    return self:draw(dt)
  end
end

--Has to be overwritten
function base:_update(dt) end
function base:draw(dt) end
function base:pressed(x,y) return false end --Called when the mouse/touch is pressed.
function base:dragged(x,y,dx,dy) end --Called when the mouse/touch is moved while down.
function base:released(x,y) end --Called when the mouse/touch is released after returning try from base:pressed.

--Internal functions to handle multitouch and computer mouse
function base:_mousepressed(x,y,b,istouch)
  if self.down or istouch then return end
  self.mousepress = true
  self.down = true
  self.mousepress = self:pressed(x,y,b)
  self.down = self.mousepress
  return self.mousepress
end

function base:_mousemoved(x,y,dx,dy,istouch)
  if istouch or (not self.down) then return end
  self:dragged(x,y,dx,dy)
  return true
end

function base:_mousereleased(x,y,b,istouch)
  if istouch or (not self.down) then return end
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

function base:_touchmoved(id,x,y,dx,dy)
  if (not self.touchid) or self.mousepress or self.touchid ~= id then return end
  self:dragged(x,y,dx,dy)
  return true
end

function base:_touchreleased(id,x,y)
  if (not self.touchid) or self.mousepress or self.touchid ~= id then return end
  self.down = false
  self:released(x,y)
  self.touchid = nil
  return true
end

return base