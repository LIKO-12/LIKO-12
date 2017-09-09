local path = select(1,...):sub(1,-(string.len("imageButton")+1))

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

--Button with a text label
local imgbtn = class("DiskOS.GUI.imageButton",base)

--Default Values:


function imgbtn:initialize(gui,text,x,y,align,w,h)
  base.initialize(self,gui,x,y,w,h)
  
  
end

--Draw the imgbtn
function imgbtn:draw()
  local fgcol = self:getFGColor()
  local bgcol = self:getBGColor()
  local x,y = self:getPosition()
  local w,h = self:getSize()
  local text = self:getText()
  local down = self:isDown()
  
  if down then
    fgcol,bgcol = bgcol,fgcol
  end
  
  rect(x,y,w,h,false,fgcol)
  color(bgcol)
  print(text,x+1,y+1,w-1,self.align)
end

--Internal functions--

--Handle cursor press
function imgbtn:pressed(x,y)
  if isInRect(x,y,{self:getRect()}) then
    self:draw() --Update the button
    return true
  end
end

--Handle cursor release
function imgbtn:released(x,y)
  if isInRect(x,y,{self:getRect()}) then
    if self.onclick then
      self:onclick()
    end
  end
  
  self:draw() --Update the button
end

--Provide prefered cursor
function imgbtn:cursor(x,y)
  local down = self:isDown()
  
  if isInRect(x,y,{self:getRect()}) then
    if down then
      return "handpress"
    else
      return "handrelease"
    end
  end
end

return imgbtn