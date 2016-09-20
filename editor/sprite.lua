local s = {}

local basexx = require("libraries.basexx")

local img, mflag
local imgw, imgh = 8, 8 --Image Width, Image Height
local psize = 10 --Zoomed Pixel Size
local imgdraw = {3+1,8+3+1,0,psize,psize} --Image Location
local imgrecto = {3,3+8,psize*imgw+2,psize*imgh+2,1}
local imggrid = {3+1,8+3+1,psize*imgw,psize*imgh,imgw,imgh}

local sprsrecto = {1,128-(8+24+1),192,24+2, 1} --SpriteSheet Outline Rect
local sprsdraw = {1,128-(8+24)} --SpriteSheet Draw Location
local sprsgrid = {1,128-(8+24),192,8*3,24,3}
local sprssrect = {0,128-(8+24+1),8+2,8+2,8} --SpriteSheet Select Rect
local sprsidrect = {192-(36+13),128-(8+24+9),13,7,7,14}
local sprsbanksY = 128 - (8+24+9)
local sprsbanksgrid = {192-32,sprsbanksY+1,8*4,8,4,1}
local sprsid = 1 --SpriteSheet Selected ID
local sprsmflag = false

local sprsbquads = {} --SpriteSheet 6 BanksQuads
local sprsbank = 1 --Current Selected Bank

local temp = 0
local palimg = api.Image(api.ImageData(4,4):map(function() temp = temp + 1 return temp end ))
local palrecto = {192-(psize*4+3),8+3,psize*4+2,psize*4+2,1}
local paldraw = {192-(psize*4+2),8+3+1,0,psize,psize}
local palgrid = {192-(psize*4+2),8+3+1,psize*4,psize*4,4,4}

local colsrectL = {192-(psize*4+3),8+3,psize+2,psize+2,8}
local colsrectR = {192-(psize*4+2),8+3+1,psize,psize,1}
local colsL --Color Select Left
local colsR --Color Select Right

function s:_switch()
  sprsbquads = {}
  local sprsimg = api.SpriteMap:image()
  for i = 1, 4 do
    sprsbquads[i] = sprsimg:quad(1,(i*8*3-8*3)+1,_,3*8)
  end
  
  img = api.ImageData(imgw,imgh):map(function() return 0 end)
  mflag = false
  
  --self:redraw()
end

function s:export(path)
  local FileData = api.SpriteMap:data():export(path)
  if not path then
    return basexx.to_base64(FileData:getString())
  end
end

function s:load(path)
  if path then
    api.SpriteMap = api.SpriteSheet(api.Image("/"..path..".png"),24,12)
  else
    api.SpriteMap = api.SpriteSheet(api.ImageData(24*8,12*8):image(),24,12)
  end
end

function s:redrawCP() --Redraw color pallete
  api.rect_line(unpack(palrecto))
  palimg:draw(unpack(paldraw))
  api.rect_line(unpack(colsrectR))
  api.rect_line(unpack(colsrectL))
end

function s:redrawSPRS()
  api.rect(unpack(sprsrecto))
  api.SpriteMap:image():draw(sprsdraw[1],sprsdraw[2],sprsdraw[3],sprsdraw[4],sprsdraw[5],sprsbquads[sprsbank])
  api.rect_line(unpack(sprssrect))
  api.rect(unpack(sprsidrect))
  api.color(sprsidrect[6])
  local id = sprsid if id < 10 then id = "00"..id elseif id < 100 then id = "0"..id end
  api.print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  api.SpriteGroup(49,192-32,sprsbanksY,4,1,1,1,api.EditorSheet)
  api.EditorSheet:draw(sprsbank+24,192-(40-sprsbank*8),sprsbanksY)
end

function s:redrawSPR()
  api.rect(unpack(imgrecto))
  api.SpriteMap:image():draw(imgdraw[1],imgdraw[2],imgdraw[3],imgdraw[4],imgdraw[5],api.SpriteMap:quad(sprsid))
end

function s:_redraw()
  self:redrawCP()
  self:redrawSPR()
  self:redrawSPRS()
end

function s:_mpress(x,y,b,it)
  --if api.isInRect(x,y,{1,1,192,8}) then api.SpriteMap:data():export("editorsheet") end
  local cx, cy = api.whereInGrid(x,y,palgrid)
  if cx then
    if b == 1 then
      colsL = (cy-1)*4+cx if colsL == 1 then colsL = 0 end
      local cx, cy = cx-1, cy-1
      colsrectL[1] = 192-(psize*4+3)+psize*cx
      colsrectL[2] = 8+3+psize*cy
    elseif b == 2 then
      colsR = (cy-1)*4+cx if colsR == 1 then colsR = 0 end
      local cx, cy = cx-1, cy-1
      colsrectR[1] = 192-(psize*4+2)+psize*cx
      colsrectR[2] = 8+3+1+psize*cy
    end
    
    self:redrawCP()
  end
  
  local cx = api.whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = api.floor((sprsid-1)/(24*3))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*24*3 elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*24*3 end
    self:redrawSPRS() self:redrawSPR()
  end
  
  local cx, cy = api.whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = 128-(8+24+1)+cy*8
    
    self:redrawSPRS() self:redrawSPR() sprsmflag = true
  end
  
  
  local cx, cy = api.whereInGrid(x,y,imggrid)
  if cx then
    if not it then mflag = true end
    local data = api.SpriteMap:data()
    local qx,qy = api.SpriteMap:rect(sprsid)
    local col = b == 1 and colsL or colsR
    data:setPixel(qx+cx-1,qy+cy-1,col)
    api.SpriteMap.img = data:image()
    self:redrawSPR() self:redrawSPRS()
  end
end

function s:_mmove(x,y,dx,dy,it,iw)
  if iw then return end
  if (not it and mflag) or it then
    local cx, cy = api.whereInGrid(x,y,imggrid)
    if cx then
      local data = api.SpriteMap:data()
      local qx,qy = api.SpriteMap:rect(sprsid)
      local col = api.isMDown(1) and colsL or colsR
      data:setPixel(qx+cx-1,qy+cy-1,col)
      api.SpriteMap.img = data:image()
      self:redrawSPR() self:redrawSPRS()
    end
  end
  
  if (not it and sprsmflag) or it then
    local cx, cy = api.whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = 128-(8+24+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR()
    end
  end
end

function s:_mrelease(x,y,b,it)
  if (not it and mflag) or it then
    local cx, cy = api.whereInGrid(x,y,imggrid)
    if cx then
      local data = api.SpriteMap:data()
      local qx,qy = api.SpriteMap:rect(sprsid)
      local col = b == 1 and colsL or colsR
      data:setPixel(qx+cx-1,qy+cy-1,col)
      api.SpriteMap.img = data:image()
      self:redrawSPR() self:redrawSPRS()
    end
    mflag = false
  end
  
  if (not it and sprsmflag) or it then
    local cx, cy = api.whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = 128-(8+24+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR() sprsmflag = false
    end
  end
end

return s