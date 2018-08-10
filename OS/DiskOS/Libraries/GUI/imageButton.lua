local path = select(1,...):sub(1,-(string.len("imageButton")+1))
local class = require("Libraries.middleclass")

local base = require(path..".base")

--Button with a text label
local imgbtn = class("DiskOS.GUI.imageButton",base)

function imgbtn:initialize(gui,container,x,y)
  base.initialize(self,gui,container,x,y,0,0)

  --self.fimg <- The image when the button is not held
  --self.bimg <- The image when the button is held
  --self.img <- The image when using single-image mode.
  --self.fcol <- The front color in single-image mode.
  --self.bcol <- The back color in singel-image mode.
end

function imgbtn:setImage(img,fcol,bcol,nodraw)
  if not nodraw then self:clear() end
  
  self.fimg, self.bimg = nil, nil
  self.img, self.fcol, self.bcol = img or self.img, fcol or self.fcol, bcol or self.bcol

  if self.img and type(self.img) ~= "number" then
    local imgW, imgH = self.img:size()
    self:setSize(imgW,imgH,true)
  end
  if not nodraw then self:draw() end

  return self
end

function imgbtn:setFrontImage(img,nodraw)
  if not nodraw then self:clear() end
  
  self.img, self.fcol, self.bcol = nil,nil,nil
  self.fimg = img

  if self.fimg and type(self.fimg) ~= "number" then
    local imgW, imgH = self.fgimg:size()
    self:setSize(imgW,imgH,true)
  end
  if not nodraw then self:draw() end

  return self
end

function imgbtn:setBackImage(img,nodraw)
  if not nodraw then self:clear() end
  
  self.img, self.fcol, self.bcol = nil,nil,nil
  self.bimg = img

  if self.bimg and type(self.bimg) ~= "number" then
    local imgW, imgH = self.bgimg:size()
    self:setSize(imgW,imgH,true)
  end
  if not nodraw then self:draw() end

  return self
end

function imgbtn:getImage() return self.img, self.fcol, self.bcol end
function imgbtn:getFrontImage() return self.fimg end
function imgbtn:getBackImage() return self.bimg end

--Draw the imgbtn
function imgbtn:draw()
  local lightcol = self:getLightColor()
  local darkcol = self:getDarkColor()

  local fimg = self:getFrontImage()
  local bimg = self:getBackImage()

  local img, fcol, bcol = self:getImage()

  local sheet = self:getSheet()

  local x,y = self:getPosition()
  local down = self:isDown()

  if down then
    lightcol, darkcol = darkcol, lightcol
  end

  if img then --Single-image Mode
    pushPalette()
    pal(fcol,darkcol)
    pal(bcol,lightcol)
    if type(img) == "number" then --SpriteSheet mode
      sheet:draw(img,x,y)
    else --Normal image
      img:draw(x,y)
    end
    popPalette()
  else --Multiple images
    local i = down and bimg or fimg

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

return imgbtn