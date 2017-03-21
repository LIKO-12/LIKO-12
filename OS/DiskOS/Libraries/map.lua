local path = select(1,...)
return function(w,h,sheet)
  local Map = {}
  
  Map.w, Map.h = w or 24, h or 9
  --Initialize the map table
  Map.m = {}
  for x=1, Map.w do
    Map.m[x] = {}
    for y=1, Map.h do
      Map.m[x][y] = 0
    end
  end
  Map.sheet = sheet

  --If called with a function, it will be called on everycell with x,y,sprid args
  --The function can return an new sprid to set
  --If called with no args, it will return the map table.
  function Map:map(func)
    if func then
      for x=1, self.w do
        for y=1, self.h do
          self.m[x][y] = func(x,y,self.m[x][y]) or self.m[x][y]
          --func(x,y,self.m[x][y])
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
    local nMap = require(path)(w,h)
    local m = nMap:map()
    for my=1,h do
      for mx=1,w do
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
  
  function Map:draw(dx,dy,x,y,w,h,sx,sy,sheet)
    local dx,dy,x,y,w,h,sx,sy = dx or 1, dy or 1, x or 1, y or 1, w or self.w, h or self.h, sx or 1, sy or 1
    local cm = self:cut(x,y,w,h)
    cm:map(function(spx,spy,sprid)
      if sprid < 1 then return end
      (self.sheet or sheet):draw(sprid,dx + spx*8*sx - 8*sx, dy + spy*8*sy - 8*sy, 0, sx, sy)
    end)
    return self
  end
  
  function Map:export()
    local data = "LK12;TILEMAP;"..self.w.."x"..self.h..";"
    self:map(function(x,y,sprid)
      data = data..sprid..";"
    end)
    return data
  end
  
  function Map:import(data)
    if not data:sub(0,13) == "LK12;TILEMAP;" then error("Wrong header") end
    local w,h,mdata = string.match(data,"LK12;TILEMAP;(%d+)x(%d+);(.+)")
    local nextid = mdata:gmatch("(.-);")
    self:map(function(x,y,sprid)
      return tonumber(nextid())
    end)
    return self
  end
  
  return Map
end