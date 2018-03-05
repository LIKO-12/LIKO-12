local eapi = ...
local MapObj = require("Libraries.map")

local t = {} --The tilemap editor

local imgw, imgh = 8, 8 --The sprite size (MUST NOT CHANGE)

local swidth, sheight = screenSize() --The screen size
local sheetW, sheetH = math.floor(swidth/imgw), math.floor(sheight/imgh) --The size of the spritessheet in cells (sprites)
local bankH = sheetH/4 --The height of each bank in cells (sprites)
local bsizeH = bankH*imgh --The height of each bank in pixels
local sizeW, sizeH = sheetW*imgw, sheetH*imgh --The size of the spritessheet in pixels

local SpriteMap --We be recieved later in t:entered()

local MapW, MapH = math.floor(swidth*0.75), sheight --The size of the map in cells.

local MapPW, MapPH = MapW*8, MapH*8 --The map size in pixels.

local MapVW, MapVH = swidth/8, sheight/8 --The visible map space in cells.

local MapVPW, mapVPH = MapVW*8, MapVH*8 --The visible map space in pixels.

local Map = MapObj(MapW, MapH)

local mapdx, mapdy = 0,0 --Map drawing offsets.

local bgsprite = eapi.editorsheet:extract(59):image() --The background image sprite.
local bgquad = bgsprite:quad(0,0,MapVPW,MapVPH) --The quad of the background image.

function t:entered()
  SpriteMap = eapi.leditors[eapi.editors.sprite].SpriteMap
  eapi:drawUI()
  self:redraw()
end

function t:redraw()
  
end

function t:drawToolbar()
  
end

function t:drawMap()
  --Clip to map area
  clip(0,8,swidth-8,sheight-8)
  
  --Draw the background.
  pal(1,2) --Change blue to red.
  bgsprite:draw(0,8, 0,1,1, bgquad)
  pal() --Reset blue to blue.
  local bgx, bgy = 0,0
  if mapdx < 0 then bgx = -mapdx end
  if mapdy < 0 then bgy = -mapdy end
  if mapdx > MapPW-MapVPW then bgx = MapPW-MapVPW-mapdx end
  if mapdy > MapPH-MapVPH then bgy = MapPH-MapVPH-mapdy end
  bgsprite:draw(bgx,bgy+8, 0,1,1, bgquad)
  
  --Draw the map
  
  --Declip
  clip()
end

function t:export()
  return Map:export()
end

function t:encode()
  return RamUtils.mapToBin(Map)
end

function t:import(data)
  if data then
    Map:import(data)
  else
    Map = MapObj(MapW,MapH)
  end
end

function t:decode(data)
  RamUtils.binToMap(Map,data)
end

return t