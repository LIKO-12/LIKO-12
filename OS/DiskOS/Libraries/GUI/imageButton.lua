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


function imgbtn:initialize(gui,x,y)--,w,h)
  base.initialize(self,gui,x,y,w,h)
  
  --self.fgimg <- The image when the button is not held
  --self.bgimg <- The image when the button is held
  --self.img <- The image when using single-image mode.
  --self.fcol <- The front color in single-image mode.
  --self.bcol <- The back color in singel-image mode.
end

function imgbtn:setImage(img,fcol,bcol,nodraw)
  self.fgimg, self.bgimg = nil, nil
  self.img, self.fcol, self.bcol = img or self.img, fcol or self.fcol, bcol or self.bcol
  
  if self.img and type(self.img) ~= "number" then
    local imgW, imgH = self.img:size()
    self:setSize(imgW,imgH,true)
  end
  if not nodraw then self:draw() end
  
  return self
end

function imgbtn:setFGImage(img,nodraw)
  self.img, self.fcol, self.bcol = nil,nil,nil
  self.fgimg = img
  
  if self.fgimg and type(self.fgimg) ~= "number" then
    local imgW, imgH = self.fgimg:size()
    self:setSize(imgW,imgH,true)
  end
  if not nodraw then self:draw() end
  
  return self
end

function imgbtn:setBGImage(img,nodraw)
  self.img, self.fcol, self.bcol = nil,nil,nil
  self.bgimg = img
  
  if self.bgimg and type(self.bgimg) ~= "number" then
    local imgW, imgH = self.bgimg:size()
    self:setSize(imgW,imgH,true)
  end
  if not nodraw then self:draw() end
  
  return self
end

function imgbtn:getImage() return self.img, self.fcol, self.bcol end
function imgbtn:getFGImage() return self.fgimg end
function imgbtn:getBGImage() return self.bgimg end

--Draw the imgbtn
function imgbtn:draw()
  local fgcol = self:getFGColor()
  local bgcol = self:getBGColor()
  
  local fgimg = self:getFGImage()
  local bgimg = self:getBGImage()
  
  local img, fcol, bcol = self:getImage()
  
  local sheet = self:getSheet()
  
  local x,y = self:getPosition()
  local down = self:isDown()
  
  if down then
    fgcol, bgcol = bgcol, fgcol
  end
  
  if img then --Single-image Mode
    pushPalette()
    pal(fcol,bgcol)
    pal(bcol,fgcol)
    if type(img) == "number" then --SpriteSheet mode
      sheet:draw(img,x,y)
    else --Normal image
      img:draw(x,y)
    end
    popPalette()
  else --Multiple images
    local i = down and bgimg or fgimg
    
    if type(i) == "number" then --SpriteSheet mode
      sheet:draw(i,x,y)
    else --Normal image
      i:draw(x,y)
    end
  end
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