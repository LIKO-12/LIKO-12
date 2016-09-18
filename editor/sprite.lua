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
local palimg = Image(ImageData(4,4):map(function() temp = temp + 1 return temp end ))
local palrecto = {192-(psize*4+3),8+3,psize*4+2,psize*4+2,1}
local paldraw = {192-(psize*4+2),8+3+1,0,psize,psize}
local palgrid = {192-(psize*4+2),8+3+1,psize*4,psize*4,4,4}

local colsrecto = {192-(psize*4+3),8+3,psize+2,psize+2,8}
local colsrect = {192-(psize*4+2),8+3+1,psize,psize,1}
local cols

function s:_switch()
  cols = 0
  
  sprsbquads = {}
  local sprsimg = SpriteMap:image()
  for i = 1, 4 do
    sprsbquads[i] = sprsimg:quad(1,(i*8*3-8*3)+1,_,3*8)
  end
  
  img = ImageData(imgw,imgh):map(function() return 0 end)
  mflag = false
  
  --self:redraw()
end

function s:export(path)
  local FileData = SpriteMap:data():export(path)
  if not path then
    return basexx.to_base64(FileData:getString())
  end
end

function s:load(path)
  if path then
    SpriteMap = SpriteSheet(Image("/"..path..".png"),24,12)
  else
    SpriteMap = SpriteSheet(ImageData(24*8,12*8):image(),24,12)
  end
end

function s:redrawCP() --Redraw color pallete
  rect_line(unpack(palrecto))
  palimg:draw(unpack(paldraw))
  rect_line(unpack(colsrect))
  rect_line(unpack(colsrecto))
end

function s:redrawSPRS()
  rect(unpack(sprsrecto))
  SpriteMap:image():draw(sprsdraw[1],sprsdraw[2],sprsdraw[3],sprsdraw[4],sprsdraw[5],sprsbquads[sprsbank])
  rect_line(unpack(sprssrect))
  rect(unpack(sprsidrect))
  color(sprsidrect[6])
  local id = sprsid if id < 10 then id = "00"..id elseif id < 100 then id = "0"..id end
  print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  SpriteGroup(49,192-32,sprsbanksY,4,1,EditorSheet)
  EditorSheet:draw(sprsbank+24,192-(40-sprsbank*8),sprsbanksY)
end

function s:redrawSPR()
  rect(unpack(imgrecto))
  SpriteMap:image():draw(imgdraw[1],imgdraw[2],imgdraw[3],imgdraw[4],imgdraw[5],SpriteMap:quad(sprsid))
end

function s:_redraw()
  self:redrawCP()
  self:redrawSPR()
  self:redrawSPRS()
end

function s:_mpress(x,y,b,it)
  --if isInRect(x,y,{1,1,192,8}) then SpriteMap:data():export("editorsheet") end
  local cx, cy = whereInGrid(x,y,palgrid)
  if cx then
    cols = (cy-1)*4+cx if cols == 1 then cols = 0 end
    local cx, cy = cx-1, cy-1
    colsrecto[1] = 192-(psize*4+3)+psize*cx
    colsrecto[2] = 8+3+psize*cy
    colsrect[1] = 192-(psize*4+2)+psize*cx
    colsrect[2] = 8+3+1+psize*cy
    
    self:redrawCP()
  end
  
  local cx = whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = floor((sprsid-1)/(24*3))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*24*3 elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*24*3 end
    self:redrawSPRS() self:redrawSPR()
  end
  
  local cx, cy = whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = 128-(8+24+1)+cy*8
    
    self:redrawSPRS() self:redrawSPR() sprsmflag = true
  end
  
  
  local cx, cy = whereInGrid(x,y,imggrid)
  if cx then
    if not it then mflag = true end
    local data = SpriteMap:data()
    local qx,qy = SpriteMap:rect(sprsid) 
    data:setPixel(qx+cx-1,qy+cy-1,cols)
    SpriteMap.img = data:image()
    self:redrawSPR() self:redrawSPRS()
  end
end

function s:_mmove(x,y,dx,dy,it,iw)
  if iw then return end
  if (not it and mflag) or it then
    local cx, cy = whereInGrid(x,y,imggrid)
    if cx then
      local data = SpriteMap:data()
      local qx,qy = SpriteMap:rect(sprsid)
      data:setPixel(qx+cx-1,qy+cy-1,cols)
      SpriteMap.img = data:image()
      self:redrawSPR() self:redrawSPRS()
    end
  end
  
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
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
    local cx, cy = whereInGrid(x,y,imggrid)
    if cx then
      local data = SpriteMap:data()
      local qx,qy = SpriteMap:rect(sprsid)
      data:setPixel(qx+cx-1,qy+cy-1,cols)
      SpriteMap.img = data:image()
      self:redrawSPR() self:redrawSPRS()
    end
    mflag = false
  end
  
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
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