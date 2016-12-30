
local basexx = require("libraries.basexx")

local t = {}

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
for i = 1, 4 do
  sprsbquads[i] = api.SpriteMap:image():quad(1,(i*8*3-8*3)+1,_,3*8)
end

local mapgrid = {1,9,192,9*8,24,9}
local mapmflag = false

function t:export(path)
  local FileData = api.TileMap:export(path)
  if not path then
    return basexx.to_base64(FileData:getString())
  end
end

--[[function t:load(path)
  local map = api.Map
  if path then
    api.SpriteMap = api.SpriteSheet(api.Image("/"..path..".png"),24,12)
  else
    api.SpriteMap = api.SpriteSheet(api.ImageData(24*8,12*8):image(),24,12)
  end
end]]

function t:_switch()
  sprsmflag = false
end

function t:_redraw()
  self:redrawMap()
  self:redrawSPRS()
end

function t:redrawMap()
  api.rect(1,9,api.TileMap:width()*8,api.TileMap:height()*8,1)
  api.TileMap:draw(1,9)
end

function t:redrawSPRS()
  api.rect(unpack(sprsrecto))
  api.SpriteMap:image():draw(sprsdraw[1],sprsdraw[2],sprsdraw[3],sprsdraw[4],sprsdraw[5],sprsbquads[sprsbank])
  api.rect_line(unpack(sprssrect))
  api.rect(unpack(sprsidrect))
  api.color(sprsidrect[6])
  local id = sprsid if id < 10 then id = "00"..id elseif id < 100 then id = "0"..id end
  api.print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  api.SpriteGroup(97,192-32,sprsbanksY,4,1,1,1,api.EditorSheet)
  api.EditorSheet:draw(sprsbank+72,192-(40-sprsbank*8),sprsbanksY)
  api.rect(sprsidrect[1]-9,sprsidrect[2]-1,8,8,1)
  api.SpriteMap:image():draw(sprsidrect[1]-9,sprsidrect[2]-1,0,1,1,api.SpriteMap:quad(sprsid))
end

function t:_mpress(x,y,b,it)
  local cx = api.whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = api.floor((sprsid-1)/(24*3))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*24*3 elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*24*3 end
    self:redrawSPRS()
  end
  
  local cx, cy = api.whereInGrid(x,y,mapgrid)
  if cx then
    api.TileMap:cell(cx,cy,sprsid)
    
    self:redrawMap() mapmflag = true
  end
  
  local cx, cy = api.whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = 128-(8+24+1)+cy*8
    
    self:redrawSPRS() sprsmflag = true
  end
end

function t:_mmove(x,y,dx,dy,it,iw)
  local cx, cy = api.whereInGrid(x,y,mapgrid)
  if cx and mapmflag then
    api.TileMap:cell(cx,cy,sprsid)
    
    self:redrawMap()
  end
  
  if (not it and sprsmflag) or it then
    local cx, cy = api.whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = 128-(8+24+1)+cy*8
      
      self:redrawSPRS()
    end
  end
end

function t:_mrelease(x,y,b,it)
  local cx, cy = api.whereInGrid(x,y,mapgrid)
  if cx and mapmflag then
    api.TileMap:cell(cx,cy,sprsid)
    
    self:redrawMap()
  end
  mapmflag = false
  
  if (not it and sprsmflag) or it then
    local cx, cy = api.whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = 128-(8+24+1)+cy*8
      
      self:redrawSPRS()
    end
  end
  sprsmflag = false
end

return t