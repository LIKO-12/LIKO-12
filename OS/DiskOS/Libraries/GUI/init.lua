--DiskOS LIKO-12 GUI Library
local path = select(1,...)
local objectsPath = "C:/"..path:gsub("%.","/").."/"

local GUI = class("DiskOS.GUI")

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

--Default internal values:
GUI.static.fgcol = 9 --Foreground Color
GUI.static.bgcol = 4 --Background Color
GUI.static.tcol = 7 --Text color

--Create new GUI state:
--fgcol -> The default forground color.
--bgcol -> The default background color.
--tcol -> The defaul text color.
--w,h -> The size of the screen.
function GUI:initialize(sheet,fgcol,bgcol,tcol,w,h)
  self._objects = {} --The objects that can be created.
  self.objects = {} --Registered objects
  
  self.sheet = sheet
  
  self.w = w or screenWidth()
  self.h = h or screenHeight()
  self.fw = fw or fontWidth()
  self.fh = fh or fontHeight()
  
  self.fgcol = GUI.static.fgcol or fgcol
  self.bgcol = GUI.static.bgcol or bgcol
  self.tcol = GUI.static.tcol or tcol
  
  self:loadDefaultObjects()
end

--Load default objects
function GUI:loadDefaultObjects()
  --Load default objects
  local files = fs.directoryItems(objectsPath)
  for k, objfile in ipairs(files) do
    if objfile ~= "init.lua" then
      local objname = objfile:sub(1,-5)
      self:newObjectClass(objname,require(path.."."..objname))
    end
  end
  return self
end

--Register a new object class
function GUI:newObjectClass(name,c)
  self._objects[name] = c
  return self
end

--Get an object class
function GUI:getObjectClass(name) return self._objects[name] end

--Register a new object
function GUI:register(obj)
  table.insert(self.objects,obj)
end

--Create a new object
function GUI:newObject(name,...)
  local objclass = self:getObjectClass(name) --Get the object class from the loaded objects list
  
  local obj = objclass(self,...) --Create a new object
  self:register(obj) --Register the object in this GUI instance so it's events get called.
  
  return obj --Return the created object
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

--Set the default spritesheet
function GUI:setSheet(sheet) self.sheet = sheet or self.sheet; return self end
function GUI:getSheet() return self.sheet end

--Return registered objects list
function GUI:getObjects() return self.objects end

--Hooks
function GUI:event(event,a,b,c,d,e,f)
  if event ~= "draw" then
    event = "_"..event
  end
  
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
  
  if event == "_mousepressed" or event == "_mousereleased" then
    self:_mousemoved(a,b,0,0,d)
  end
end

function GUI:redraw()
  self:event("draw")
end

function GUI:_mousemoved(x,y,dx,dy,istouch)
  if istouch then return end
  
  for k, obj in ipairs(self:getObjects()) do
    if obj.cursor then
      local c = obj:cursor(x,y)
      if c then
        cursor(c)
        return
      end
    end
  end
  
  cursor("normal") --Defaults to the normal cursor
end

return GUI