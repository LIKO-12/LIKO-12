local path = select(1,...):sub(1,-(string.len("container")+1))
local class = require("Libraries.middleclass")

--Container object class
local container = class("DiskOS.GUI.container")

--Default internal values:
container.static.lightcol = 9 --The light color
container.static.darkcol = 4 --The dark color
container.static.bgcol = 0 --Background color
container.static.tcol = 7 --Text color

--Create a new objects container:
--<gui>: The GUI instance of this container.
--[x],[y]: The position of the top-left corner of the object.
--[w],[h]: The size of the object.
function container:initialize(gui,parentContainer,x,y,w,h,bgcol,tcol,lightcol,darkcol,sheet)
  self.gui = gui or error("GUI State has to be passed",2)
  self.container = parentContainer or error("Container has to be passed",2)
  
  self.objects = {} --Registered objects
  
  self.x = x or 0
  self.y = y or 0
  self.w = w or screenWidth()
  self.h = h or screenHeight()
  
  self.visible = true
  
  if self.container == self then
  
    self.sheet = sheet
    
    self.lightcol = lightcol or container.static.lightcol
    self.darkcol = darkcol or container.static.darkcol
    self.bgcol = bgcol or container.static.bgcol
    self.tcol = tcol or container.static.tcol
    
  else
    
    self:setLightColor(lightcol or self.container:getLightColor(),true)
    self:setDarkColor(darkcol or self.container:getDarkColor(),true)
    self:setBGColor(bgcol or self.container:getBGColor(),true)
    self:setTColor(tcol or self.container:getTColor(),true)

    self:setSheet(sheet or self.container:getSheet(),true)
    
  end
end

--Get object GUI instance.
function container:getGUI()
  return self.gui
end

--Get object parent container.
function container:getContainer()
  return self.container
end

--Set object visiblilty
function container:setVisible(visible,nodraw)
  self.visible = visible or false

  if not self.visible then
    self.down, self.touchid, self.mousepressed = false, false, false
    if not nodraw then self:clear() end
  end
end

function container:isVisible()
  return self.visible
end

--Set object position.
function container:setX(x,nodraw)
  if not nodraw then self:clear() end

  self.x = x or self.x
  if not nodraw then self:draw() end

  return self
end

function container:setY(y,nodraw)
  if not nodraw then self:clear() end

  self.y = y or self.y
  if not nodraw then self:draw() end

  return self
end

function container:setPosition(x,y,nodraw)
  if not nodraw then self:clear() end

  self:setX(x,true)
  self:setY(y,true)

  if not nodraw then self:draw() end

  return self
end

--Get object position
function container:getX() return self.x end
function container:getY() return self.y end
function container:getPosition() return self:getX(), self:getY() end

--Set object size
function container:setWidth(w,nodraw)
  if not nodraw then self:clear() end
  self.w = w or self.w
  if not nodraw then self:draw() end

  return self
end

function container:setHeight(h,nodraw)
  if not nodraw then self:clear() end
  self.h = h or self.h
  if not nodraw then self:draw() end

  return self
end

function container:setSize(w,h,nodraw)
  if not nodraw then self:clear() end

  self:setWidth(w,true)
  self:setHeight(h,true)

  if not nodraw then self:draw() end

  return self
end

--Get object size
function container:getWidth() return self.w end
function container:getHeight() return self.h end
function container:getSize() return self:getWidth(), self:getHeight() end

function container:setRect(x,y,w,h,nodraw)
  if not nodraw then self:clear() end

  self:setPosition(x,y,true)
  self:setSize(x,y,true)

  if not nodraw then self:draw() end

  return self
end

function container:getRect()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  return x,y,w,h
end

--Set object colors
function container:setLightColor(lightcol,nodraw)
  if not nodraw then self:clear() end
  self.lightcol = lightcol or self.lightcol
  if not nodraw then self:draw() end
  return self
end

function container:setDarkColor(darkcol,nodraw)
  if not nodraw then self:clear() end
  self.darkcol = darkcol or self.darkcol
  if not nodraw then self:draw() end
  return self
end

function container:setBGColor(bgcol,nodraw)
  if not nodraw then self:clear() end
  self.bgcol = bgcol or self.bgcol
  if not nodraw then self:draw() end
  return self
end

function container:setTColor(tcol,nodraw)
  if not nodraw then self:clear() end
  self.tcol = tcol or self.tcol
  if not nodraw then self:draw() end
  return self
end

function container:setColors(lightcol,darkcol,bgcol,tcol,nodraw)
  if not nodraw then self:clear() end

  self:setLightColor(lightcol,true)
  self:setDarkColor(darkcol,true)
  self:setBGColor(bgcol,true)
  self:setTColor(tcol,true)

  if not nodraw then self:draw() end

  return self
end

--Get object colors
function container:getLightColor() return self.lightcol end
function container:getDarkColor() return self.darkcol end
function container:getBGColor() return self.bgcol end
function container:getTColor() return self.tcol end
function container:getColors() return self:getLightColor(), self:getDarkColor(), self:getBGColor(), self:getTColor() end

--Set the object sheet
function container:setSheet(sheet,nodraw)
  if not nodraw then self:clear() end
  self.sheet = sheet or self.sheet
  if not nodraw then self:draw() end
  return self
end

--Get the object sheet
function container:getSheet() return self.sheet end

--Register a new object
function container:register(obj)
  table.insert(self.objects,obj)
end

--Return registered objects list
function container:getObjects() return self.objects end

--Create a new object
function container:newObject(name,...)
  local objclass = self.gui:getObjectClass(name) --Get the object class from the loaded objects list
  
  if not objclass then return error("Object '"..name.."' doesn't exist !") end
  
  local obj = objclass(self.gui,self,...) --Create a new object
  self:register(obj) --Register the object in this GUI instance so it's events get called.

  return obj --Return the created object
end

--Clear previous draw area.
function container:clear()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local bgColor = self.container:getBGColor()
  rect(x,y,w,h,false,bgColor)
end

--Draw the container
function container:_draw(dt)
  if self:isVisible() then
    local x,y = self:getPosition()
    local w,h = self:getSize()
    local bgColor = self:getBGColor()
    rect(x,y,w,h,false,bgColor)
    
    self:event("draw")
  end
end

--Hooks
function container:event(event,a,b,c,d,e,f)
  event = "_"..event

  if self[event] and event ~= "_draw" then
    if self[event](self,a,b,c,d,e,f) then
      return true --Event consumed
    end
  end
  
  local x,y = self:getPosition()
  
  pushMatrix()
  cam("translate",x,y)
  
  if event:sub(2,6) == "mouse" then
    a,b = a-x, b-y
  elseif event:sub(2,6) == "touch" then
    b,c = b-x, c-y
  end
  
  local consumed = false --Did the even get consumed ?

  for k, obj in ipairs(self:getObjects()) do
    if obj.event and event ~= "_draw" then
      if obj:event(event:sub(2,-1),a,b,c,d,e,f) then
        consumed = true
        break --Event consumed
      end
    elseif obj[event] then
      if obj[event](obj,a,b,c,d,e,f) then
        consumed = true
        break --Event consumed
      end
    end
  end
  
  popMatrix()

  if event == "_mousepressed" or event == "_mousereleased" then
    self:_mousemoved(a,b,0,0,d)
  end
  
  return consumed
end

function container:draw()
  self:_draw()
  self:event("draw")
end

function container:_mousemoved(x,y,dx,dy,istouch)
  if istouch then return end
  
  local cx,cy = self:getPosition()
  
  for k, obj in ipairs(self:getObjects()) do
    if obj.cursor then
      local c = obj:cursor(x-cx,y-cy)
      if c then
        return c
      end
    end
  end
end

function container:cursor(x,y)
  return self:_mousemoved(x,y,0,0,false)
end

return container