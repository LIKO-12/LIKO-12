local eapi = select(1,...) --The editor library is provided as an argument

local se = {} --Sprite Editor

local swidth, sheight = screenSize()

local SpriteMap, mflag = SpriteSheet(imagedata(24*8,12*8):image(),24,12), false
local imgw, imgh = 8, 8
local psize = 10 --Zoomed pixel size
local imgdraw = {3+1,8+3+1, 0, psize,psize} --Image Location
local imgrecto = {3,3+8,psize*imgw+2,psize*imgh+2,true,1}
local imggrid = {3+1,8+3+1, psize*imgw,psize*imgh, imgw,imgh}

local sprsrecto = {1,sheight-(8+24+1+1),swidth,24+2, true, 1} --SpriteSheet Outline Rect
local sprsdraw = {1,sheight-(8+24)} --SpriteSheet Draw Location
local sprsgrid = {1,sheight-(8+24),swidth,8*3,24,3}
local sprssrect = {0,sheight-(8+24+1+1),8+2,8+2,true,8} --SpriteSheet Select Rect
local sprsidrect = {swidth-(36+13),sheight-(8+24+9), 13,7, false, 7}
local sprsbanksY = sheight - (8+24+9)
local sprsbanksgrid = {swidth-32,sprsbanksY+1, 8*4,8, 4,1}
local sprsid = 1 --SpriteSheet Selected ID
local sprsmflag = false
local sprsbquads = {} --SpriteSheets 4 BanksQuads
local sprsbank = 1 --Current Selected Bank
for i = 1, 4 do
  sprsbquads[i] = eapi.editorsheet:image():quad(1,(i*8*3-8*3)+1,_,3*8)
end

local temp = 0
local palpsize = 13
local palimg = imagedata(4,4):map(function() temp = temp + 1 return temp end ):image()
local palrecto = {swidth-(palpsize*4+3),8+3, palpsize*4+2,palpsize*4+2, true, 1}
local paldraw = {swidth-(palpsize*4+2),8+3+1,0,palpsize,palpsize}
local palgrid = {swidth-(palpsize*4+2),8+3+1,palpsize*4,palpsize*4,4,4}

local colsrectL = {swidth-(palpsize*4+3),8+3,palpsize+2,palpsize+2, true, 8}
local colsrectR = {swidth-(palpsize*4+2),8+3+1,palpsize,palpsize, true, 1}
local colsL = 0 --Color Select Left
local colsR = 0 --Color Select Right

local toolsdraw = {104, swidth-102,sprsbanksY-2, 5,1, 1,1, eapi.editorsheet} --Tools Draw Config
local toolsgrid = {toolsdraw[2],toolsdraw[3], toolsdraw[4]*8,toolsdraw[5]*8, toolsdraw[4],toolsdraw[5]} --Tools Selection Grid
local stool = 1

local tbtimer = 0
local tbtime = 0.1125
local tbflag = false

local transdraw = {109, swidth-105,sprsbanksY-15, 5,1, 1,1, eapi.editorsheet} --Transformations Draw Config
local transgrid = {transdraw[2],transdraw[3], transdraw[4]*8, transdraw[5]*8, transdraw[4], transdraw[5]} --Transformations Selection Grid
local strans --Selected Transformation

local transtimer
local transtime = 0.1125

local infotimer = 0 --The info timer, 0 if no info.
local infotext = "" --The info text to display

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
    local qx,qy = api.SpriteMap:rect(sprsid)
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
    infotimer, infotext = 2,"DELETED SPRITE "..sprsid s:redrawINFO()
  end
}

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
  clipboard(b64enc(SpriteMap:extract(sprsid):encode()))
  infotimer = 2 --Show info for 2 seconds
  infotext = "COPIED SPRITE "..sprsid
  self:redrawINFO()
end

function se:paste()
  local ok, err = pcall(function()
    local dx,dy,dw,dh = SpriteMap:rect(sprsid)
    local sheetdata = SpriteMap:data()
    sheetdata:paste(b64dec(clipboard() or ""),dx,dy,1,1,dw,dh)
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
    SpriteMap = SpriteSheet(image("/"..path..".lk12"),24,12)
  else
    SpriteMap = SpriteSheet(imagedata(24*8,12*8):image(),24,12)
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
  color(sprsidrect[6])
  local id = sprsid if id < 10 then id = "00"..id elseif id < 100 then id = "0"..id end
  print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  SpriteGroup(97,swidth-32,sprsbanksY,4,1,1,1,eapi.editorsheet)
  eapi.editorsheet:draw(sprsbank+72,192-(40-sprsbank*8),sprsbanksY)
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
  SpriteGroup(126,swidth-64,sprsbanksY-18,8,1,1,1,eapi.editorsheet)
  SpriteGroup(126,swidth-64,sprsbanksY-10,8,1,1,1,eapi.editorsheet)
end

function se:redrawINFO()
  rect(1,sheight-7,swidth,8,10)
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
    sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = sheight-(8+24+1)+cy*8
    
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
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sheight-(8+24+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR()
    end
  end
end

function se:mouserelease(x,y,b,it)
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
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sheight-(8+24+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR()
    end
  end
  sprsmflag = false
end

local bank = function(bank)
  return function()
    local idbank = math.floor((sprsid-1)/(24*3))+1
    sprsbank = bank
    if idbank > sprsbank then
      sprsid = sprsid-(idbank-sprsbank)*24*3
    elseif sprsbank > idbank then
      sprsid = sprsid+(sprsbank-idbank)*24*3
    end
    s:redrawSPRS() s:redrawSPR()
  end
end

se.keymap = {
  ["ctrl-c"] = se.copy,
  ["ctrl-v"] = se.paste,
  ["1"] = bank(1), ["2"] = bank(2), ["3"] = bank(3), ["4"] = bank(4),
  ["z"] = function() stool=1 s:redrawTOOLS() end,
  ["x"] = function() stool=2 s:redrawTOOLS() end,
  ["delete"] = function() tools[5](s) se:redrawSPRS() se:redrawSPR() end,
}

return se