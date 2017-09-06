local path = select(1,...):sub(1,-(string.len("button")+1))

local base = require(path..".base")

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

return button