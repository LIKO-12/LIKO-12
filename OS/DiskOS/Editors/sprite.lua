local eapi = select(1,...) --The editor library is provided as an argument

local se = {} --Sprite Editor

local imgw, imgh = 8, 8 --The sprite size (MUST NOT CHANGE)

local swidth, sheight = screenSize() --The screen size
local sheetW, sheetH = math.floor(swidth/imgw), math.floor(sheight/imgh) --The size of the spritessheet in cells (sprites)
local bankH = sheetH/4 --The height of each bank in cells (sprites)
local bsizeH = bankH*imgh --The height of each bank in pixels
local sizeW, sizeH = sheetW*imgw, sheetH*imgh --The size of the spritessheet in pixels

local SpriteMap, mflag = SpriteSheet(imagedata(sizeW,sizeH):image(),sheetW,sheetH), false --The spritemap, plus mouse drawing flag

--[[The configuration tables scheme:
draw: spriteID, x,y, w,h, spritesheet| OR: x,y, 0, w,h (marked by IMG_DRAW)
rect: x,y, w,h, isline, colorid
grid: gridX,gridY, gridW,gridH, cellW, cellH
]]

--SpriteSheet Sprite Selection--
local sprsrecto = {1,sheight-(8+bsizeH+1), swidth,bsizeH+2, false, 1} --SpriteSheet Outline Rect
local sprsdraw = {1,sheight-(8+bsizeH)} --SpriteSheet Draw Location; IMG_DRAW
local sprsgrid = {sprsdraw[1],sprsdraw[2], sizeW,bsizeH, sheetW,bankH} --The SpriteSheet selection grid
local sprssrect = {sprsrecto[1],sprsrecto[2], imgw+2,imgh+2, true, 8} --SpriteSheet Select Rect (that white box on the selected sprite)
local sprsbanksgrid = {swidth-(4*8+1),sheight-(sprsrecto[1]+8), 8*4,8, 4,1} --The grid of banks selection buttons
local sprsid = 1 --Selected Sprite ID
local sprsmflag = false --Sprite selection mouse flag
local sprsbquads = {} --SpriteSheets 4 BanksQuads
local sprsbank = 1 --Current Selected Bank
for i = 1, 4 do --Create the banks quads
  sprsbquads[i] = eapi.editorsheet:image():quad(1,(i*8*bankH-8*bankH)+1,_,bankH*8)
end

local maxSpriteIDCells = tostring(sheetW*sheetH):len() --The number of digits in the biggest sprite id.
local sprsidrect = {sprsbanksgrid[1]-(1+maxSpriteIDCells*4+3),sprsbanksgrid[2], 1+maxSpriteIDCells*4,7, false, 7, 14} --The rect of sprite id; The extra argument is the color of number print
local revdraw = {sprsidrect[1]-(imgw+1),sprsrecto[2]-(imgh+1)} --The small image at the right of the id with the actual sprite size

--The current sprite flags--
local flagsgrid = {swidth-(8*7+2),revdraw[2]-(8+2), 8*7,6, 8,1} --The sprite flags grid
local flagsdraw = {flagsgrid[1]-1,flagsgrid[2]-1} --The position of the first (leftmost) flag
local flags = 0 --All 00000000

--Tools Selection--
local toolsdraw = {104, revdraw[1]-(8*5+4),revdraw[2], 5,1, 1,1, eapi.editorsheet} --Tools draw arguments
local toolsgrid = {toolsdraw[2],toolsdraw[3], toolsdraw[4]*8,toolsdraw[5]*8, toolsdraw[4],toolsdraw[5]} --Tools Selection Grid
local stool = 1 --Current selected tool id

local tbtimer = 0 --Tool selection blink timer
local tbtime = 0.1125 --The blink time
local tbflag = false --Is the blink timer activated ?

--Transformations Selection--
local transdraw = {109, flagsgrid[1]-(8*5+3),toolsdraw[3]-(8+2), 5,1, 1,1, eapi.editorsheet} --Transformations draw arguments
local transgrid = {transdraw[2],transdraw[3], transdraw[4]*8, transdraw[5]*8, transdraw[4], transdraw[5]} --Transformations Selection Grid
local strans --Selected Transformation

local transtimer --The transformation blink timer
local transtime = 0.1125 --The blink time

--------------------------------------------

--The Sprite (That you are editing--
local psize = 9 --Zoomed pixel size
local imgdraw = {3+1,8+3+1, 0, psize,psize} --Image Location; IMG_DRAW
local imgrecto = {3,3+8,psize*imgw+2,psize*imgh+2, false,1} --The image outline rect position
local imggrid = {3+1,8+3+1, psize*imgw,psize*imgh, imgw,imgh} --The image drawing grid

--The Color Selection Pallete--
local temp = 0 --Temporary Variable
local palpsize = 13 --The size of each color box in the color selection pallete
local palimg = imagedata(4,4):map(function() temp = temp + 1 return temp end ):image() --The image of the color selection pallete
local palrecto = {swidth-(palpsize*4+3),8+3, palpsize*4+2,palpsize*4+2, true, 1} --The outline rectangle of the color selection pallete
local paldraw = {swidth-(palpsize*4+2),8+3+1,0,palpsize,palpsize} --The color selection pallete draw arguments; IMG_DRAW
local palgrid = {swidth-(palpsize*4+2),8+3+1,palpsize*4,palpsize*4,4,4} --The color selection pallete grid

local colsrectL = {swidth-(palpsize*4+3),8+3,palpsize+2,palpsize+2, true, 8} --The color select box for the left mouse button (The black one)
local colsrectR = {swidth-(palpsize*4+2),8+3+1,palpsize,palpsize, true, 1} --The color select box for the right mouse button (The white one)
local colsL = 0 --Selected Color for the left mouse
local colsR = 0 --Selected Color for the right mouse

--Info system variables--
local infotimer = 0 --The info timer, 0 if no info.
local infotext = "" --The info text to display

--The tools code--
local toolshold = {true,true,false,false,false} --Is it a button (Clone, Stamp, Delete) or a tool (Pencil, fill)
local tools = {
  function(self,cx,cy,b) --Pencil (Default)
    local data = SpriteMap:data()
    local qx,qy = SpriteMap:rect(sprsid)
    local col = (b == 1 or isMDown(1)) and colsL or colsR
    data:setPixel(qx+cx-1,qy+cy-1,col)
    SpriteMap.img = data:image()
  end,

  function(self,cx,cy,b) --Fill (Bucket)
    local data = SpriteMap:data()
    local qx,qy = SpriteMap:rect(sprsid)
    local col = (b == 1 or isMDown(1)) and colsL or colsR
    local tofill = data:getPixel(qx+cx-1,qy+cy-1)
    if tofill == col then return end
    local function spixel(x,y) if x >= qx and x <= qx+7 and y >= qy and y <= qy+7 then data:setPixel(x,y,col) end end
    local function gpixel(x,y) if x >= qx and x <= qx+7 and y >= qy and y <= qy+7 then return data:getPixel(x,y) else return false end end
    local function mapPixel(x,y)
      if gpixel(x,y) and gpixel(x,y) == tofill then spixel(x,y) end
      if gpixel(x+1,y) and gpixel(x+1,y) == tofill then mapPixel(x+1,y) end
      if gpixel(x-1,y) and gpixel(x-1,y) == tofill then mapPixel(x-1,y) end
      if gpixel(x,y+1) and gpixel(x,y+1) == tofill then mapPixel(x,y+1) end
      if gpixel(x,y-1) and gpixel(x,y-1) == tofill then mapPixel(x,y-1) end
    end
    mapPixel(qx+cx-1,qy+cy-1)
    SpriteMap.img = data:image()
  end,

  function(self) --Clone (Copy)
    self:copy()
  end,

  function(self) --Stamp (Paste)
    self:paste()
  end,

  function(self) --Delete (Erase)
    local data = SpriteMap:data()
    local qx,qy = SpriteMap:rect(sprsid)
    for px = 0, 7 do for py = 0, 7 do
      data:setPixel(qx+px,qy+py,0)
    end end
    SpriteMap.img = data:image()
    infotimer, infotext = 2,"DELETED SPRITE "..sprsid se:redrawINFO()
  end
}

--The transformations code--
local function transform(tfunc)
  local current = SpriteMap:extract(sprsid)
  local new = imagedata(current:width(),current:height())
  current:map(function(x,y,c)
    local nx,ny,nc = tfunc(x,y,c,current:width(),current:height())
    new:setPixel(nx or x,ny or y,nc or c)
  end)
  local x,y = SpriteMap:rect(sprsid)
  local data = SpriteMap:data()
  data:paste(new:export(),x,y)
  SpriteMap.img = data:image()
end

local transformations = {
  function(x,y,c,w,h) return h+1-y,x end, --Rotate right
  function(x,y,c,w,h) return y, w+1-x end, --Rotate left
  function(x,y,c,w,h) return w+1-x,y end, --Flip horizental
  function(x,y,c,w,h) return x,h+1-y end, --Flip vertical
  function(x,y,c,w,h) return w+1-x,h+1-y end --Flip horizentaly + verticaly
}

function se:entered()
  eapi:drawUI()
  self:_redraw()
end

function se:leaved()
  
end

function se:export(path)
  return SpriteMap:data():encode()
end

function se:copy()
  clipboard(math.b64enc(SpriteMap:extract(sprsid):export()))
  infotimer = 2 --Show info for 2 seconds
  infotext = "COPIED SPRITE "..sprsid
  self:redrawINFO()
end

function se:paste()
  local ok, err = pcall(function()
    local dx,dy,dw,dh = SpriteMap:rect(sprsid)
    local sheetdata = SpriteMap:data()
    sheetdata:paste(math.b64dec(clipboard()),dx,dy)
    SpriteMap.img = sheetdata:image()
    self:_redraw()
  end)
  if not ok then
    infotimer = 5 --Display error msg for 5 seconds
    infotext = "PASTE ERR: "..(err or "nil")
  else
    infotimer = 2 --Display info for 2 seconds
    infotext = "PASTED TO SPRITE "..sprsid
  end
  self:redrawINFO()
end

function se:load(path)
  if path then
    SpriteMap = SpriteSheet(image("/"..path..".lk12"),sheetW,sheetH)
  else
    SpriteMap = SpriteSheet(imagedata(sizeW,sizeH):image(),sheetW,sheetH)
  end
end

function se:redrawCP() --Redraw color pallete
  rect(palrecto)
  palimg:draw(unpack(paldraw))
  rect(colsrectR)
  rect(colsrectL)
end

function se:redrawSPRS()
  rect(sprsrecto)
  SpriteMap:image():draw(sprsdraw[1],sprsdraw[2],sprsdraw[3],sprsdraw[4],sprsdraw[5],sprsbquads[sprsbank])
  rect(sprssrect)
  rect(sprsidrect)
  color(sprsidrect[7])
  local id = sprsid if id < 10 then id = "00"..id elseif id < 100 then id = "0"..id end
  print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  SpriteGroup(97,swidth-32,sprsbanksY,4,1,1,1,eapi.editorsheet)
  eapi.editorsheet:draw(sprsbank+72,swidth-(40-sprsbank*8),sprsbanksY)
end

function se:redrawSPR()
  rect(imgrecto)
  SpriteMap:image():draw(imgdraw[1],imgdraw[2],imgdraw[3],imgdraw[4],imgdraw[5],SpriteMap:quad(sprsid))
  rect(sprsidrect[1]-9,sprsidrect[2]-1,8,8,false,1)
  SpriteMap:image():draw(sprsidrect[1]-9,sprsidrect[2]-1,0,1,1,SpriteMap:quad(sprsid))
end

function se:redrawTOOLS()
  --Tools
  SpriteGroup(unpack(toolsdraw))
  eapi.editorsheet:draw((toolsdraw[1]+(stool-1))-24,toolsdraw[2]+(stool-1)*8,toolsdraw[3],0,toolsdraw[6],toolsdraw[7])
  
  --Transformations
  SpriteGroup(unpack(transdraw))
  if strans then eapi.editorsheet:draw((transdraw[1]+(strans-1))-24,transdraw[2]+(strans-1)*8,transdraw[3],0,transdraw[6],transdraw[7]) end
end

function se:redrawFLAG()
  --SpriteGroup(126,swidth-64,sprsbanksY-18,8,1,1,1,eapi.editorsheet)
  SpriteGroup(126,swidth-64,sprsbanksY-10,8,1,1,1,eapi.editorsheet)
end

function se:redrawINFO()
  rect(1,sheight-7,swidth,8,false,10)
  if infotimer > 0 then
    color(5)
    print(infotext or "",2,sheight-5)
  end
end

function se:_redraw()
  self:redrawCP()
  self:redrawSPR()
  self:redrawSPRS()
  self:redrawFLAG()
  self:redrawTOOLS()
end

function se:update(dt)
  if tbflag then
    tbtimer = tbtimer + dt
    if tbtime <= tbtimer then
      stool = tbflag
      tbflag = false
      self:redrawTOOLS()
    end
  end
  
  if transtimer then
    transtimer = transtimer + dt
    if transtimer > transtime then
      transtimer, strans = nil, nil
      self:redrawTOOLS()
    end
  end
  
  if infotimer > 0 then
    infotimer = infotimer - dt
    if infotimer < 0 then
      infotimer = 0
      self:redrawINFO()
    end
  end
end

function se:mousepressed(x,y,b,it)
  --Pallete Color Selection
  local cx, cy = whereInGrid(x,y,palgrid)
  if cx then
    if b == 1 then
      colsL = (cy-1)*4+cx if colsL == 1 then colsL = 0 end
      local cx, cy = cx-1, cy-1
      colsrectL[1] = swidth-(palpsize*4+3)+palpsize*cx
      colsrectL[2] = 8+3+palpsize*cy
    elseif b == 2 then
      colsR = (cy-1)*4+cx if colsR == 1 then colsR = 0 end
      local cx, cy = cx-1, cy-1
      colsrectR[1] = swidth-(palpsize*4+2)+palpsize*cx
      colsrectR[2] = 8+3+1+palpsize*cy
    end
    
    self:redrawCP()
  end
  
  --Bank selection
  local cx = whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = math.floor((sprsid-1)/(24*3))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*24*3 elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*24*3 end
    self:redrawSPRS() self:redrawSPR()
  end
  
  --Sprite Selection
  local cx, cy = whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = sheight-(8+bsizeH+1)+cy*8
    
    self:redrawSPRS() self:redrawSPR() sprsmflag = true
  end
  
  --Tool Selection
  local cx, cy = whereInGrid(x,y,toolsgrid)
  if cx then
    if toolshold[cx] then
      stool = cx
      self:redrawTOOLS()
      self:redrawSPRS() self:redrawSPR()
    else
      tools[cx](self)
      tbflag, tbtimer = stool, 0
      stool = cx
      self:redrawSPRS() self:redrawSPR() self:redrawTOOLS()
    end
  end
  
  --Transformation Selection
  local cx, cy = whereInGrid(x,y,transgrid)
  if cx and transformations[cx] then
    transform(transformations[cx]) transtimer, strans = 0, cx
    self:redrawSPRS() self:redrawSPR() self:redrawTOOLS()
  end
  
  --Image Drawing
  local cx, cy = whereInGrid(x,y,imggrid)
  if cx then
    if not it then mflag = true end
    tools[stool](self,cx,cy,b)
    self:redrawSPR() self:redrawSPRS()
  end
end

function se:mousemoved(x,y,dx,dy,it,iw)
  if iw then return end
  
  --Image Drawing
  if (not it and mflag) or it then
    local cx, cy = whereInGrid(x,y,imggrid)
    if cx then
      tools[stool](self,cx,cy)
      self:redrawSPR() self:redrawSPRS()
    end
  end
  
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sheight-(8+bsizeH+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR()
    end
  end
end

function se:mousereleased(x,y,b,it)
  --Image Drawing
  if (not it and mflag) or it then
    local cx, cy = whereInGrid(x,y,imggrid)
    if cx then
      tools[stool](self,cx,cy,b)
      self:redrawSPR() self:redrawSPRS()
    end
  end
  mflag = false
  
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sheight-(8+bsizeH+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR()
    end
  end
  sprsmflag = false
end

local bank = function(bank)
  return function()
    local idbank = math.floor((sprsid-1)/(sheetW*bankH))+1
    sprsbank = bank
    if idbank > sprsbank then
      sprsid = sprsid-(idbank-sprsbank)*sheetW*bankH
    elseif sprsbank > idbank then
      sprsid = sprsid+(sprsbank-idbank)*sheetW*bankH
    end
    se:redrawSPRS() se:redrawSPR()
  end
end

se.keymap = {
  ["ctrl-c"] = se.copy,
  ["ctrl-v"] = se.paste,
  ["1"] = bank(1), ["2"] = bank(2), ["3"] = bank(3), ["4"] = bank(4),
  ["z"] = function() stool=1 se:redrawTOOLS() end,
  ["x"] = function() stool=2 se:redrawTOOLS() end,
  ["delete"] = function() tools[5](s) se:redrawSPRS() se:redrawSPR() end,
}

return se