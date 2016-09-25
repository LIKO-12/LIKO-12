local lume = require("libraries.lume")
local m = {}

local w,h = 92,64

local imgw, imgh = 8, 8
local mapvw, mapvh = 24, 9
local mapgrid = {1,8+3,mapvw*imgw,mapvh*imgh,mapvw,mapvh}
local maprect = {1,8+3,mapvw*imgw,mapvh*imgh}

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

local xo, yo = 0, 0 -- offsets
local map = {}

function m:set(celx, cely, snum)
  assert(celx > 0 and celx <= w and cely > 0 and cely <= h, "out of bounds")
  map[cely][celx] = snum
end

function m:get(celx, cely)
  return map[cely][celx]
end

-- this function gets exposed to the sandbox API
function m.api_draw(cel_x, cel_y, sx, sy, cel_w, cel_h)
  local to_x, to_y = sx, sy
  for my=cel_y,cel_y+(cel_h or h-cel_y) do
    for mx=cel_x,cel_x+(cel_w or w-cel_x) do
      local sprite_id = map[my][mx]
      if(sprite_id and sprite_id > 0) then
        api.Sprite(sprite_id, to_x, to_y)
      end
      to_x = to_x + imgw
    end
    to_y, to_x = to_y + imgh, sx
  end
end

function m:_switch()
  for y=1,h do
    map[y] = map[y] or {}
    for x=1,w do
      map[y][x] = map[y][x] or 0
    end
  end
end

function m:redrawMap()
  api.color(1)
  api.rect(unpack(maprect))
  for y=1,mapvh do
    for x=1,mapvw do
      if(map[y][x] > 0) then
        api.Sprite(map[y][x], (x-1+xo)*8+1, (y-1+yo)*8+9)
      end
    end
  end
end

function m:redrawSPRS() -- sprite sheet along the bottom
  api.rect(unpack(sprsrecto))
  api.SpriteMap:image():draw(sprsdraw[1],sprsdraw[2],sprsdraw[3],sprsdraw[4],
                             sprsdraw[5],sprsbquads[sprsbank])
  api.rect_line(unpack(sprssrect))
  api.rect(unpack(sprsidrect))
  api.color(sprsidrect[6])
  local id = sprsid
  if id < 10 then id = "00"..id elseif id < 100 then id = "0"..id end
  api.SpriteGroup(49,192-32,sprsbanksY,4,1,1,1,api.EditorSheet)
  api.EditorSheet:draw(sprsbank+24,192-(40-sprsbank*8),sprsbanksY)
end

function m:_redraw()
  m:redrawSPRS()
  m:redrawMap()
end

function m:_mpress(x,y,b,it)
  local cx = api.whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = floor((sprsid-1)/(24*3))+1
    if idbank > sprsbank then
      sprsid = sprsid-(idbank-sprsbank)*24*3
    elseif sprsbank > idbank then
      sprsid = sprsid+(sprsbank-idbank)*24*3
    end
    self:redrawSPRS()
  end

  local cx, cy = api.whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = 128-(8+24+1)+cy*8

    self:redrawSPRS()
    sprsmflag = true
  end

  local cx, cy = api.whereInGrid(x,y,mapgrid)
  if cx then
    if not it then mflag = true end
    map[cy][cx] = sprsid
    self:redrawMap()
  end
end

function m:_mmove()
end

function m:_mrelease(x,y,b,it)
end

function m:export()
  return lume.serialize(map)
end

function m:load(m)
  map = m and lume.deserialize(m) or {}
end

return m
