--DiskOS LIKO-12 GUI Library

local class = require("Libraries.middleclass")

local GUI = class("DiskOS.GUI")
local objects = {} --Table containing default objects.

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

--Default internal values:
GUI.static.fgcol = 9 --Foreground Color
GUI.static.bgcol = 4 --Background Color
GUI.static.tcol = 7 --Text color

--Create new GUI state:
--fgcol -> The default forground color.
--bgcol -> The default background color.
--tcol -> The defaul text color.
--w,h -> The size of the screen.
function GUI:initialize(fgcol,bgcol,tcol,w,h)
 self._objects = {} --The objects that can be created.
 self.objects = {} --Registered objects

 self.w = w or screenWidth()
 self.h = h or screenHeight()
 self.fw = fw or fontWidth()
 self.fh = fh or fontHeight()

 self.fgcol = GUI.static.fgcol or fgcol
 self.bgcol = GUI.static.bgcol or bgcol
 self.tcol = GUI.static.tcol or tcol
end

--Register a new object
function GUI:register(obj)
 table.insert(self.objects,obj)
end

--Set the screen dimensions
function GUI:setWidth(w) self.w = w or self.w; return self end
function GUI:setHeight(h) self.h = h or self.h; return self end
function GUI:setSize(w,h)
 self.w = w or self.w
 self.h = h or self.h
 return self
end

--Return the screen dimensions
function GUI:getWidth() return self.w end
function GUI:getHeight() return self.h end
function GUI:getSize() return self.w, self.h end

--Get font size
function GUI:getFontWidth() return self.fw end
function GUI:getFontHeight() return self.fh end
GUI.getFW = wrap("getFontWidth")
GUI.getFH = wrap("getFontHeight")

--Set default colors.
function GUI:setFGColor(fgcol) self.fgcol = fgcol or self.fgcol; return self end
function GUI:setBGColor(bgcol) self.bgcol = bgcol or self.bgcol; return self end
function GUI:setTColor(tcol) self.tcol = tcol or self.tcol; return self end
function GUI:setColors(fgcol,bgcol,tcol)
 self:setFGColor(fgcol)
 self:setBGColor(bgcol)
 self:setTColor(tcol)
 return self
end

--Get default colors
function GUI:getFGColor() return self.fgcol end
function GUI:getBGColor() return self.bgcol end
function GUI:getTColor() return self.tcol end
function GUI:getColors() return self:getFGColor(), self:getBGColor(), self:getTColor() end

--Return registered objects list
function GUI:getObjects() return self.objects end

--Hooks
function GUI:event(event,a,b,c,d,e,f)
 event = "_"..event
 if self[event] then
  if self[event](self,a,b,c,d,e,f) then
   return
  end
 end
 
 for k, obj in ipairs(self:getObjects()) do
  if obj[event] then
    if obj[event](obj,a,b,c,d,e,f) then
     break
    end
  end
 end
 
 if event == "_update" then
  self:event("draw",a,b,c,d,e,f)
 end
end

--Base object class
local base = class("DiskOS.GUI.base")

function base:initialize(gui,x,y,w,h)
 self.gui = gui or error("GUI State has to be passed",2)
 
 self.x, self.y = 0, 0
 self.w, self.h = 0, 0
 
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
function base:_draw(dt) return self end
function base:_update(dt) return self end

--Button with a text label
local button = class("DiskOS.GUIbutton",base)

--Default Values:
button.static.text = "Button"                                                                

function button:initialize(gui,text,x,y,w,h)
 base.initialize(self,gui,x,y,w,h)
 
 self:setText(text or button.static.text)
end

function button:setText(t)
 self.text = t or self.text
 
 local fw = self.gui:getFontWidth()
 local fh = self.gui:getFontHeight()
 self:setWidth(1+(fw+1)*self.text:len())
 self:setHeight(fh+2)
 
 return self
end

function button:getText() return self.text end

function button:_draw()
 local fgcol = self:getFGColor()
 local bgcol = self:getBGColor()
 local x,y = self:getPosition()
 local w,h = self:getSize()
 local text = self:getText()
 
 rect(x,y,w,h,false,fgcol)
 color(bgcol)
 print(text,x+1,y+1)
end

--GUI TEST
local tgui = GUI()
local tbtn = button(tgui,"TEST",5,5)
tgui:register(tbtn)

clear()

for event, a,b,c,d,e,f in pullEvent do
 if event == "keypressed" then
  if a == "escape" then return end
 end
 
 tgui:event(event,a,b,c,d,e,f)
end

return GUI