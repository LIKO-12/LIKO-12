local eapi, img, imgdata = ... --Check C:/Programs/paint.lua

local sw, sh = screenSize()

local paint = {}

--The palette image
paint.pal = imagedata(16,1)
paint.pal:map(function(x,y,c) return x end)
paint.pal = paint.pal:image()

--Selected colors
paint.fgcolor, paint.bgcolor = 7,0

--The color selection grid
paint.palGrid = {sw-16*8,sh-8,16*8,8,16,1}

--The image drawing arguments
paint.imageDraw = {0,0 ,0, 1,1}

--The rectangle where the image is visible
local imagerect = {0,8,sw,sh-2*8}

--Zoom Slider--
local zSliderDraw = {94, 8*3,sh-8, 4,1}
local zSliderGrid = {zSliderDraw[2],zSliderDraw[3], zSliderDraw[4]*8,zSliderDraw[5]*8, zSliderDraw[4],zSliderDraw[5]} --Tools Selection Grid
local zSliderHandle = 93
local zSlider = 1 --Current slider value
local zsflag = false --Zoom slider flag

--Tools Selection--
local toolsdraw = {190, 0,sh-8, 3,1, 1,1,false, _SystemSheet} --Tools draw arguments
local toolsgrid = {toolsdraw[2],toolsdraw[3], toolsdraw[4]*8,toolsdraw[5]*8, toolsdraw[4],toolsdraw[5]} --Tools Selection Grid
local stool = 1 --Current selected tool id

local tbtimer = 0 --Tool selection blink timer
local tbtime = 0.1125 --The blink time
local tbflag = false --Is the blink timer activated ?

local pflag = false --Pan tool flag
local poldx, poldy --Pan old call coords

--The tools code--
local toolshold = {true,true,true} --Is it a button (Clone, Stamp, Delete) or a tool (Pencil, fill)
local tools = {
  function(self,x,y,b,state) --Pencil (Default)
    if self.readonly then _systemMessage("The image is readonly !",1,9,4) return end
    if state == "outmove" or state == "outrelease" then return end
    local data = imgdata
    local col = (b == 1 or isMDown(1)) and self.fgcolor or self.bgcolor
    data:setPixel(x,y,col)
    img = data:image()
  end,

  function(self,cx,cy,b,state) --Fill (Bucket)
    if self.readonly then _systemMessage("The image is readonly !",1,9,4) return end
    if state == "outmove" or state == "outrelease" then return end
    local data = imgdata
    local col = (b == 1 or isMDown(1)) and self.fgcolor or self.bgcolor
    ImageUtils.queuedFill(data,cx,cy,col)
    img = data:image()
  end,

  function(self,x,y,b,state) --Pan (Hand)
    if state == "press" and not pflag then
      pflag = true
      poldx, poldy = x, y
    elseif (state == "move" or state == "outmove") and pflag then
      local dx, dy = x-poldx, y-poldy
      self.imageDraw[1] = self.imageDraw[1]+dx
      self.imageDraw[2] = self.imageDraw[2]+dy
      poldx, poldy = x-dx, y-dy
    elseif (state == "release" or state == "outrelease") and pflag then
      local dx, dy = x-poldx, y-poldy
      self.imageDraw[1] = self.imageDraw[1]+dx
      self.imageDraw[2] = self.imageDraw[2]+dy
      pflag = false
    end
    self:checkPosition()
  end
}

local bgsprite = _SystemSheet:extract(59):image() --The background sprite
local bgquad = bgsprite:quad(0,0,imagerect[3],imagerect[4]) --The background quad

local mflag = false

--Draw the color selection palette
function paint:drawPalette()
  self.pal:draw(sw-16*8,sh-8,0,8,8)
end

--Draw the rectangle that shows the selected colors
function paint:drawColorCell()
  palt(0,true)
  pal(8,self.fgcolor)
  pal(12,self.bgcolor)
  _SystemSheet:draw(77,sw-16*8-8,sh-8)
  pal()
  palt(0,false)
end

--Draw the image we are editing
function paint:drawImage()
  clip(0,8,sw,sh-8*2)
  bgsprite:draw(imagerect[1],imagerect[2],0,1,1,bgquad)
  img:draw(self.imageDraw[1],8+self.imageDraw[2], self.imageDraw[3], self.imageDraw[4], self.imageDraw[5])
  clip()
end

--Draw the buttom bar of the editor
function paint:drawBottomBar()
  eapi:drawBottomBar()
  self:drawPalette()
  self:drawColorCell()
  self:drawTOOLS()
  self:drawSlider()
end

--Draw the tools selection GUI
function paint:drawTOOLS()
  SpriteGroup(unpack(toolsdraw))
  _SystemSheet:draw((toolsdraw[1]+(stool-1))-24, toolsdraw[2]+(stool-1)*8,toolsdraw[3], 0, toolsdraw[6],toolsdraw[7])
end

--Draw the zooming slider
function paint:drawSlider()
  _SystemSheet:draw(zSliderDraw[1],zSliderDraw[2],zSliderDraw[3])
  for i=2,zSliderDraw[4]-1 do
    _SystemSheet:draw(zSliderDraw[1]+1,zSliderDraw[2]+(i-1)*8,zSliderDraw[3])
  end
  _SystemSheet:draw(zSliderDraw[1]+2,zSliderDraw[2]+(zSliderDraw[4]-1)*8,zSliderDraw[3])
  
  palt(0,true)
  _SystemSheet:draw(zSliderHandle,zSliderDraw[2]+(zSlider-1)*8,zSliderDraw[3],0,zSliderDraw[6],zSliderDraw[7])
  palt(0,false)
end

function paint:entered()
  eapi:drawUI()
  palt(0,false)
  self:drawBottomBar()
  self:drawImage()
  local mx, my = getMPos()
  self:mousemoved(mx,my,0,0)
end

function paint:leaved()
  palt(0,true)
end

function paint:import(a,b)
  img, imgdata = a,b
end

function paint:export()
  return imgdata:encode()
end

function paint:update(dt)
  --Update the tools blink timer
  if tbflag then
    tbtimer = tbtimer + dt
    if tbtime <= tbtimer then
      stool = tbflag
      tbflag = false
      self:drawTOOLS()
    end
  end
end

function paint:checkPosition()
  local scalew, scaleh = self.imageDraw[4], self.imageDraw[5]
  local iw, ih = img:size(); iw, ih = iw * scalew, ih * scaleh
  local ix, iy = self.imageDraw[1], self.imageDraw[2]
  if ix > sw then ix = sw end
  if iy > sh-16 then iy = sh-16 end
  if ix+iw < 0 then ix = -iw end
  if iy+ih < 0 then iy = -ih end
  self.imageDraw[1], self.imageDraw[2] = ix, iy
end

function paint:updateCursor(x,y)
  if isInRect(x,y,imagerect) then
    if stool == 1 then --Pen
      if isMDown(2) then
        cursor("eraser",true)
      else
        cursor("pencil",true)
      end
    elseif stool == 2 then --Bucket
      cursor("bucket",true)
    elseif stool == 3 then --Pan
      cursor("hand",true)
    end
  else
    cursor("normal")
  end
end

function paint:mousepressed(x,y,b,it)
  --Palette Selection
  local cx, cy = whereInGrid(x,y,self.palGrid)
  if cx then
    if b == 1 then
      self.fgcolor = cx-1
    elseif b == 2 then
      self.bgcolor = cx-1
    end
    self:drawColorCell()
  end
  
  --Zoom Slider
  local cx, cy = whereInGrid(x,y,zSliderGrid)
  if cx and not zsflag then
    local dz = zSlider - cx
    zSlider = cx
    self.imageDraw = {self.imageDraw[1] + sw*0.25*dz,self.imageDraw[2] + sh*0.25*dz ,0, zSlider,zSlider}
    zsflag = true
    self:checkPosition()
    self:drawSlider()
    self:drawImage()
  end
  
  --Image Drawing
  if isInRect(x,y,imagerect) then
    mflag = true
    local x,y = x-imagerect[1], y-imagerect[2]
    x,y = x-self.imageDraw[1], y-self.imageDraw[2]
    x,y = math.floor(x/self.imageDraw[4]), math.floor(y/self.imageDraw[5])
    tools[stool](self,x,y,b,"press")
    self:drawImage()
  end
  
  --Tool Selection
  local cx, cy = whereInGrid(x,y,toolsgrid)
  if cx then
    if toolshold[cx] then
      stool = cx
      self:drawTOOLS()
      self:drawImage()
    else
      tools[cx](self)
      tbflag, tbtimer = stool, 0
      stool = cx
      self:drawImage() self:drawTOOLS()
    end
  end
  
  self:updateCursor(x,y)
end

function paint:mousemoved(x,y,dx,dy,it)
  --Image Drawing
  if mflag then
    if isInRect(x,y,imagerect) then
      local x,y = x-imagerect[1], y-imagerect[2]
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4]), math.floor(y/self.imageDraw[5])
      tools[stool](self,x,y,false,"move")
      self:drawImage()
    else
      local x,y = x-imagerect[1], y-imagerect[2]
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4]), math.floor(y/self.imageDraw[5])
      tools[stool](self,x,y,false,"outmove")
      self:drawImage()
    end
  end
  
  --Zoom Slider
  local cx, cy = whereInGrid(x,y,zSliderGrid)
  if cx and zsflag and cx ~= zSlider then
    local dz = zSlider - cx
    zSlider = cx
    self.imageDraw = {self.imageDraw[1] + sw*0.25*dz,self.imageDraw[2] + sh*0.25*dz ,0, zSlider,zSlider}
    self:checkPosition()
    self:drawSlider()
    self:drawImage()
  end
  
  self:updateCursor(x,y)
end

function paint:mousereleased(x,y,b,it)
  --Image Drawing
  if mflag then
    if isInRect(x,y,imagerect) then
      local x,y = x-imagerect[1], y-imagerect[2]
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4]), math.floor(y/self.imageDraw[5])
      tools[stool](self,x,y,b,"release")
      self:drawImage()
    else
      local x,y = x-imagerect[1], y-imagerect[2]
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4]), math.floor(y/self.imageDraw[5])
      tools[stool](self,x,y,b,"outrelease")
      self:drawImage()
    end
    mflag = false
  end
  mflag = false
  
  --Zoom Slider
  local cx, cy = whereInGrid(x,y,zSliderGrid)
  if cx and zsflag and cx ~= zSlider then
    local dz = zSlider - cx
    zSlider = cx
    self.imageDraw = {self.imageDraw[1] + sw*0.25*dz,self.imageDraw[2] + sh*0.25*dz ,0, zSlider,zSlider}
    self:checkPosition()
    self:drawSlider()
    self:drawImage()
  end
  zsflag = false
  
  self:updateCursor(x,y)
end

return paint