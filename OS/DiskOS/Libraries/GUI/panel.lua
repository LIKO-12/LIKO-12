local path = select(1,...):sub(1,-(string.len("panel")+1))

local container = require(path..".container")

--Panel (An objects container)
local panel = class("DiskOS.GUI.panel",container)

--Create a new panel object:
--<gui> -> The GUI instance that should contain the panel.
--[x],[y] -> The position of the top-left corner of the panel.
--[w],[h] -> The size of the panel.
function panel:initialize(gui,parentContainer,x,y,w,h,bgcolor)
  base.initialize(self,gui,parentContainer,x,y,w,h)
  
  self:setBGColor(bgcolor,true)
end

return panel