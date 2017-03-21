local eapi = select(1,...)
local MapObj = require("C://Libraries/map")

local t = {}

local imgw, imgh = 8, 8 --The sprite size (MUST NOT CHANGE)

local fw, fh = fontSize() --A font character size
local swidth, sheight = screenSize() --The screen size
local sheetW, sheetH = math.floor(swidth/imgw), math.floor(sheight/imgh) --The size of the spritessheet in cells (sprites)
local bankH = sheetH/4 --The height of each bank in cells (sprites)
local bsizeH = bankH*imgh --The height of each bank in pixels
local sizeW, sizeH = sheetW*imgw, sheetH*imgh --The size of the spritessheet in pixels

local SpriteMap

--SpriteSheet Sprite Selection--
local sprsrecto = {1,sheight-(8+bsizeH+1), swidth,bsizeH+2, false, 1} --SpriteSheet Outline Rect
local sprsdraw = {1,sheight-(8+bsizeH), 0, 1,1} --SpriteSheet Draw Location; IMG_DRAW
local sprsgrid = {sprsdraw[1],sprsdraw[2], sizeW,bsizeH, sheetW,bankH} --The SpriteSheet selection grid
local sprssrect = {sprsrecto[1]-1,sprsrecto[2], imgw+2,imgh+2, true, 8} --SpriteSheet Select Rect (that white box on the selected sprite)
local sprsbanksgrid = {swidth-(4*8+1),sprsrecto[2]-8, 8*4,8, 4,1} --The grid of banks selection buttons
local sprsid = 1 --Selected Sprite ID
local sprsmflag = false --Sprite selection mouse flag
local sprsbquads = {} --SpriteSheets 4 BanksQuads
local sprsbank = 1 --Current Selected Bank
for i = 1, 4 do --Create the banks quads
  sprsbquads[i] = eapi.editorsheet:image():quad(1,(i*bsizeH-bsizeH)+1,sizeW,bsizeH)
end

local mapH = sheetH - (1+2+bankH+1)
local mapW = sheetW

local Map = MapObj(mapW,mapH)

local mapgrid = {1,9,swidth,mapH*8,mapW,mapH}
local mapmflag = false

function t:export()
  return Map:export()
end

function t:import(data)
  if data then
    Map:import(data)
  else
    Map = MapObj(mapW,mapH)
  end
end

function t:entered()
  SpriteMap = eapi.leditors[3].SpriteMap
  eapi:drawUI()
  self:_redraw()
end

function t:leaved()
  
end

function t:_redraw()
  self:redrawMap()
  self:redrawSPRS()
end

function t:redrawMap()
  rect(1,9,Map:width()*8,Map:height()*8,false,1)
  Map:draw(1,9,false,false,false,false,false,false,SpriteMap)
end

function t:redrawSPRS() _ = nil
  rect(sprsrecto)
  SpriteMap.img:draw(sprsdraw[1],sprsdraw[2], sprsdraw[3], sprsdraw[4],sprsdraw[5], sprsbquads[sprsbank])
  rect(sprssrect)
  --[[rect(sprsidrect)
  color(sprsidrect[7])
  local id = ""; for i=1, maxSpriteIDCells-(tostring(sprsid):len()) do id = id .. "0" end; id = id .. tostring(sprsid)
  print(id,sprsidrect[1]+1,sprsidrect[2]+1)]]
  SpriteGroup(97,sprsbanksgrid[1],sprsbanksgrid[2],sprsbanksgrid[5],sprsbanksgrid[6],1,1,false,eapi.editorsheet)
  eapi.editorsheet:draw(sprsbank+72,sprsbanksgrid[1]+(sprsbank-1)*8,sprsbanksgrid[2])
end

function t:mousepressed(x,y,b,it)
  --Sprite Selection
  local cx, cy = whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = sprsrecto[2]+cy*8
    
    self:redrawSPRS() sprsmflag = true
  end
  
  --Bank selection
  local cx = whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = math.floor((sprsid-1)/(sheetW*bankH))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*sheetW*bankH elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*sheetW*bankH end
    self:redrawSPRS()
  end
  
  --Map
  local cx, cy = whereInGrid(x,y,mapgrid)
  if cx then
    Map:cell(cx,cy,sprsid)
    self:redrawMap() mapmflag = true
  end
end

function t:mousemoved(x,y,dx,dy,it)
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sprsrecto[2]+cy*8
      
      self:redrawSPRS()
    end
  end
  
  --Map
  local cx, cy = whereInGrid(x,y,mapgrid)
  if cx and mapmflag then
    Map:cell(cx,cy,sprsid)
    
    self:redrawMap()
  end
end

function t:mousereleased(x,y,b,it)
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sprsrecto[2]+cy*8
      
      self:redrawSPRS()
    end
  end
  sprsmflag = false
  
  --Map
  local cx, cy = whereInGrid(x,y,mapgrid)
  if cx and mapmflag then
    Map:cell(cx,cy,sprsid)
    
    self:redrawMap()
  end
  mapmflag = false
end

return t