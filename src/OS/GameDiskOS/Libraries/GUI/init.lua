--DiskOS LIKO-12 GUI Library
local class = require("Libraries.middleclass")

local path = (...)
local objectsPath = _SystemDrive..":/"..path:gsub("%.","/").."/"

local container = require(path..".container")

local GUI = class("DiskOS.GUI",container)

--Create new GUI state:
--[bgcol] -> The default background color.
--[sheet] -> The sprites sheet to use in objects.
--[lightcol] -> The default light color.
--[darkcol] -> The default dark color.
--[tcol] -> The defaul text color.
--[w],[h] -> The size of the screen.
function GUI:initialize(bgcol,sheet,lightcol,darkcol,tcol,x,y,w,h)
  container.initialize(self,self,self,x,y,w,h,bgcol,tcol,lightcol,darkcol,sheet)
  
  self._objects = {} --The objects that can be created.
  
  self:loadDefaultObjects()
end

--Load default objects
function GUI:loadDefaultObjects()
  --Load default objects
  local files = fs.getDirectoryItems(objectsPath)
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

function GUI:_mousemoved(x,y,dx,dy,istouch)
  if istouch then return end

  local c = container._mousemoved(self,x,y,dx,dy,istouch)

  cursor(c or "normal") --Defaults to the normal cursor
end

return GUI