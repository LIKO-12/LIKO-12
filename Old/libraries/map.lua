--Must merge this with api.lua

local Map = _Class("liko12.map")

function Map:initialize(w,h)
  self.w, self.h = w or 24, h or 9
  --Initialize the map table
  self.m = {}
  for x=1, self.w do
    self.m[x] = {}
    for y=1, self.h do
      self.m[x][y] = 0
    end
  end
end

--If called with a function, it will be called on everycell with x,y,sprid args
--The function can return an new sprid to set
--If called with no args, it will return the map table.
function Map:map(func)
  if func then
    for x=1, self.w do
      for y=1, self.h do
        --self.m[x][y] = func(x,y,self.m[x][y]) or self.m[x][y]
        func(x,y,self.m[x][y])
      end
    end
  end
  return self.m
end

function Map:cell(x,y,newID)
  if newID then
    self.m[x][y] = newID or 0
    return self
  else
    return self.m[x][y]
  end
end

function Map:cut(x,y,w,h)
  local x,y,w,h = x or 1, y or 1, w or self.w, h or self.h
  local nMap = Map(w,h)
  local m = nMap:map()
  for mx=1,w do
    for my=1,h do
      if self.m[mx+x-1] and self.m[mx+x-1][my+y-1] then
        m[mx][my] = self.m[mx+x-1][my+y-1]
      end
    end
  end
  return nMap
end

function Map:size() return self.w, self.h end
function Map:width() return self.w end
function Map:height() return self.h end

function Map:draw(dx,dy,x,y,w,h,sx,sy)
  local dx,dy,x,y,w,h,sx,sy = dx or 1, dy or 1, x or 1, y or 1, w or self.w, h or self.h, sx or 1, sy or 1
  local cm = self:cut(x,y,w,h)
  cm:map(function(spx,spy,sprid)
    if sprid < 1 then return end
    api.Sprite(sprid,dx + spx*8*sx - 8*sx, dy + spy*8*sy - 8*sy, 0, sx, sy)
  end)
  return self
end

function Map:export(filename)
  local imgdata = api.ImageData(self.w,self.h)
  self:map(function(x,y,sprid)
    if sprid > 255 then
      imgdata.imageData:setPixel(x-1,y-1,255,sprid-255,0,0)
    else
      imgdata.imageData:setPixel(x-1,y-1,sprid,0,0,0)
    end
  end)
  return imgdata:export(filename)
end

function Map:import(imgdata)
  imgdata.imageData:mapPixel(function(x,y,r,g,b,a)
    self:cell(x+1,y+1,r+g)
    return r,g,b,a
  end)
  return self
end

return Map