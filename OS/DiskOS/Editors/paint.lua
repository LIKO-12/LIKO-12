local eapi, img, imgdata = ... --Check C://Programs/paint.lua

local sw, sh = screenSize()

local paint = {}
paint.pal = imagedata(16,1)
paint.pal:map(function(x,y,c) return x-1 end)
paint.pal = paint.pal:image()

paint.drawCursor = eapi.editorsheet:extract(8):image()

paint.fgcolor, paint.bgcolor = 7,0

paint.palGrid = {sw-16*8+1,sh-7,16*8,8,16,1}

paint.imageDraw = {1,1 ,0, 1,1}

local imagerect = {1,9,sw,sh-2*8}

--Zoom Slider--
local zSliderDraw = {94, 1+8*3,sh-7, 4,1}
local zSliderGrid = {zSliderDraw[2],zSliderDraw[3], zSliderDraw[4]*8,zSliderDraw[5]*8, zSliderDraw[4],zSliderDraw[5]} --Tools Selection Grid
local zSliderHandle = 93
local zSlider = 1 --Current slider value
local zsflag = false --Zoom slider flag

--Tools Selection--
local toolsdraw = {190, 1,sh-7, 3,1, 1,1,false, eapi.editorsheet} --Tools draw arguments
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
    if state == "outmove" or state == "outrelease" then return end
    local data = imgdata
    local col = (b == 1 or isMDown(1)) and self.fgcolor or self.bgcolor
    data:setPixel(x,y,col)
    img = data:image()
  end,

  function(self,cx,cy,b,state) --Fill (Bucket)
    if state == "outmove" or state == "outrelease" then return end
    local data = imgdata
    local col = (b == 1 or isMDown(1)) and self.fgcolor or self.bgcolor
    local tofill = data:getPixel(cx-1,cy-1)
    if tofill == col then return end
    local function spixel(x,y) data:setPixel(x,y,col) end
    local function gpixel(x,y) if x >= 1 and x <= imgdata:width() and y >= y and y <= imgdata:height() then return data:getPixel(x,y) else return false end end
    local function mapPixel(x,y)
      if gpixel(x,y) and gpixel(x,y) == tofill then spixel(x,y) end
      if gpixel(x+1,y) and gpixel(x+1,y) == tofill then mapPixel(x+1,y) end
      if gpixel(x-1,y) and gpixel(x-1,y) == tofill then mapPixel(x-1,y) end
      if gpixel(x,y+1) and gpixel(x,y+1) == tofill then mapPixel(x,y+1) end
      if gpixel(x,y-1) and gpixel(x,y-1) == tofill then mapPixel(x,y-1) end
    end
    pcall(mapPixel,cx-1,cy-1)
    img = data:image()
  end,

  function(self,x,y,b,state) --Pan (Hand)
    if state == "press" and not pflag then
      pflag = true
      poldx, poldy = x, y
      cursor("hand")
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
  end
}

local bgsprite = eapi.editorsheet:extract(59):image()
local bgquad = bgsprite:quad(1,1,imagerect[3],imagerect[4])

local mflag = false

function paint:drawPalette()
  self.pal:draw(sw-16*8+1,sh-7,0,8,8)
end

function paint:drawColorCell()
  palt(0,true)
  pal(8,self.fgcolor)
  pal(12,self.bgcolor)
  eapi.editorsheet:draw(77,sw-16*8-8+1,sh-7)
  pal()
  palt(0,false)
end

function paint:drawImage()
  clip(1,9,sw,sh-8*2)
  bgsprite:draw(imagerect[1],imagerect[2],0,1,1,bgquad)
  img:draw(self.imageDraw[1],8+self.imageDraw[2], self.imageDraw[3], self.imageDraw[4], self.imageDraw[5])
  clip()
end

function paint:drawBottomBar()
  eapi:drawBottomBar()
  self:drawPalette()
  self:drawColorCell()
  self:drawTOOLS()
  self:drawSlider()
end

function paint:drawTOOLS()
  SpriteGroup(unpack(toolsdraw))
  eapi.editorsheet:draw((toolsdraw[1]+(stool-1))-24, toolsdraw[2]+(stool-1)*8,toolsdraw[3], 0, toolsdraw[6],toolsdraw[7])
end

function paint:drawSlider()
  --SpriteGroup(unpack(zSliderDraw))
  eapi.editorsheet:draw(zSliderDraw[1],zSliderDraw[2],zSliderDraw[3])
  for i=2,zSliderDraw[4]-1 do
    eapi.editorsheet:draw(zSliderDraw[1]+1,zSliderDraw[2]+(i-1)*8,zSliderDraw[3])
  end
  eapi.editorsheet:draw(zSliderDraw[1]+2,zSliderDraw[2]+(zSliderDraw[4]-1)*8,zSliderDraw[3])
  
  palt(0,true)
  eapi.editorsheet:draw(zSliderHandle,zSliderDraw[2]+(zSlider-1)*8,zSliderDraw[3],0,zSliderDraw[6],zSliderDraw[7])
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
  if tbflag then
    tbtimer = tbtimer + dt
    if tbtime <= tbtimer then
      stool = tbflag
      tbflag = false
      self:drawTOOLS()
    end
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
    self:drawSlider()
    self:drawImage()
  end
  
  --Image Drawing
  if isInRect(x,y,imagerect) then
    mflag = true
    local x,y = x-imagerect[1]+1, y-imagerect[2]+1
    x,y = x-self.imageDraw[1], y-self.imageDraw[2]
    x,y = math.floor(x/self.imageDraw[4])+1, math.floor(y/self.imageDraw[5])+1
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
end

function paint:mousemoved(x,y,dx,dy,it)
  --Image Drawing
  if mflag then
    if isInRect(x,y,imagerect) then
      local x,y = x-imagerect[1]+1, y-imagerect[2]+1
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4])+1, math.floor(y/self.imageDraw[5])+1
      tools[stool](self,x,y,false,"move")
      self:drawImage()
    else
      local x,y = x-imagerect[1]+1, y-imagerect[2]+1
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4])+1, math.floor(y/self.imageDraw[5])+1
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
    self:drawSlider()
    self:drawImage()
  end
  
  --Cursor Drawing
  if isInRect(x,y,{1,9,sw,sh-8*2}) then
    cursor("none")
    eapi:drawBackground(); self:drawImage()
    eapi:drawTopBar(); self:drawBottomBar()
    palt(0,true)
    local zx,zy = self.imageDraw[4], self.imageDraw[5]
    self.drawCursor:draw(x-3*zx,y-3*zy,0,zx,zy)
    palt(0,false)
  else
    if cursor() == "none" then eapi:drawBackground(); self:drawImage(); eapi:drawTopBar(); self:drawBottomBar() end
    if cursor() == "none" or cursor() == "draw" then cursor("normal") end
  end
end

function paint:mousereleased(x,y,b,it)
  --Image Drawing
  if mflag then
    if isInRect(x,y,imagerect) then
      local x,y = x-imagerect[1]+1, y-imagerect[2]+1
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4])+1, math.floor(y/self.imageDraw[5])+1
      tools[stool](self,x,y,b,"release")
      self:drawImage()
    else
      local x,y = x-imagerect[1]+1, y-imagerect[2]+1
      x,y = x-self.imageDraw[1], y-self.imageDraw[2]
      x,y = math.floor(x/self.imageDraw[4])+1, math.floor(y/self.imageDraw[5])+1
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
    self:drawSlider()
    self:drawImage()
  end
  zsflag = false
end

return paint