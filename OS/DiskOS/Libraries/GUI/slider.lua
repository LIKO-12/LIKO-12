local path = select(1,...):sub(1,-(string.len("slider")+1))

local base = require(path..".base")

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

--A slider
local slider = class("DiskOS.GUI.slider",base)

--Default Values:
slider.static.value = 0
slider.static.width = 5
slider.static.height = 7

--Create a new slider object:
--<gui> -> The GUI instance that should contain the button.
--[text] -> The text of the button label.
--[x],[y] -> The position of the top-left corner of the button.
--[align] -> The aligning of the button label text.
--[w],[h] -> The size of the button, automatically calculated by default.
function slider:initialize(gui,x,y,length,orientation,w,h)
  base.initialize(self,gui,x,y,w or slider.static.width,h or slider.static.height)
  
  
end

function slider:setLength()

end

function slider:setSteps()

end

function slider:setOrientation()

end

function slider:getLength()

end

function slider:getSteps()

end

function slider:getOrientation()

end

return slider