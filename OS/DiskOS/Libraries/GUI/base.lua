--Wrap a function, used to add functions alias names.
local function wrap(f)
  return function(self,...)
    local args = {pcall(self[f],self,...)}
    if args[1] then
      local function a(ok,...)
        return ...
      end
      return a(unpack(args))
    else
      return error(tostring(args[2]))
    end
  end
end

--Base object class
local base = class("DiskOS.GUI.base")

function base:initialize(gui,x,y,w,h)
  self.gui = gui or error("GUI State has to be passed",2)
  
  self.x, self.y = 0, 0
  self.w, self.h = 0, 0
  
  --self.touchid -> The object press touch id.
  --self.mousepress -> True when the object is pressed using the mouse.
  
  self:setSize(w,h)
  self:setPosition(x,y)
  
  self:setFGColor(self.gui:getFGColor())
  self:setBGColor(self.gui:getBGColor())
  self:setTColor(self.gui:getTColor())
end

--Set object position.
function base:setX(x)
  if x then
    if x < 0 then
      x = self.gui:getWidth()-self.w+x
    end
  end
  
  self.x = x or self.x
  return self
end

function base:setY(y)
  if y then
    if y < 0 then
      y = self.gui:getHeight()-self.h+y
    end
  end
  
  self.y = y or self.y
  return self
end

function base:setPos(x,y)
  self:setX(x)
  self:setY(y)
  return self
end
base.setPosition = wrap("setPos")

--Get object position
function base:getX() return self.x end
function base:getY() return self.y end
function base:getPos() return self:getX(), self:getY() end
base.getPosition = wrap("getPos")

--Set object size
function base:setWidth(w) self.w = w or self.w; return self end
function base:setHeight(h) self.h = h or self.h; return self end
function base:setSize(w,h)
 self:setWidth(w)
 self:setHeight(h)
 return self
end

--Get object size
function base:getWidth() return self.w end
function base:getHeight() return self.h end
function base:getSize() return self:getWidth(), self:getHeight() end

function base:setRect(x,y,w,h)
  self:setPosition(x,y)
  self:setSize(x,y)
  return self
end

function base:getRect()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  return x,y,w,h
end

--Set object colors
function base:setFGColor(fgcol) self.fgcol = fgcol or self.fgcol; return self end
function base:setBGColor(bgcol) self.bgcol = bgcol or self.bgcol; return self end
function base:setTColor(tcol) self.tcol = tcol or self.tcol; return self end
function base:setColors(fgcol,bgcol,tcol)
 self:setFGColor(fgcol)
 self:setBGColor(bgcol)
 self:setTColor(tcol)
 return self
end

--Get object colors
function base:getFGColor() return self.fgcol end
function base:getBGColor() return self.bgcol end
function base:getTColor() return self.tcol end
function base:getColors() return self:getFGColor(), self:getBGColor(), self:getTColor() end

--Has to be overwritten
function base:_draw(dt) end
function base:_update(dt) end
function base:pressed(x,y) return false end --Called when the mouse/touch is pressed.
function base:released(x,y) end --Called when the mouse/touch is released after returning try from base:pressed.

--Internal functions to handle multitouch
function base:_mousepressed(button,x,y)
  if self.touchid or self.mousepress then return end
  self.mousepress = true
  self.mousepress = self:pressed(x,y)
  return self.mousepress
end

function base:_mousereleased(button,x,y)
  if self.touchid or (not self.mousepress) then return end
  self:released(x,y)
  self.mousepressed = false
  return true
end

function base:_touchpressed(id,x,y)
  if self.touchid or self.mousepress then return end
  self.touchid = id
  if not self:pressed(x,y) then
    self.touchid = nil
  end
  return self.touchid
end

function base:_touchreleased(id,x,y)
  if (not self.touchid) or self.mousepress then return end
  self:released(x,y)
  self.touchid = nil
  return true
end

return base