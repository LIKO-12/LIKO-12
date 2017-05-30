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
        end
      end
    end
    return self.m
  end

  function Map:cell(x,y,newID)
    if x >= self.w or y >= self.h or x < 0 or y < 0 then return false, "out of range" end
    if newID then
      self.m[x+1][y+1] = newID or 0
      return self
    else
      return self.m[x+1][y+1]
    end
  end
  
  function Map:cut(x,y,w,h)
    local x,y,w,h = x or 0, y or 0, w or self.w-1, h or self.h-1
    local nMap = require(path)(w,h)
    local m = nMap:map()
    for my=1,h do
      for mx=1,w do
        if self.m[mx+x] and self.m[mx+x][my+y] then
          m[mx][my] = self.m[mx+x][my+y]
        end
      end
    end
    return nMap
  end
  
  function Map:size() return self.w, self.h end
  function Map:width() return self.w end
  function Map:height() return self.h end
  
  function Map:draw(dx,dy,x,y,w,h,sx,sy,sheet)
    local dx,dy,x,y,w,h,sx,sy = dx or 0, dy or 0, x or 0, y or 0, w or self.w, h or self.h, sx or 1, sy or 1
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
      return 0
    end)
    
    for x=0,w-1 do
      for y=0,h-1 do
        self:cell(x,y,tonumber(nextid()))
      end
    end
    
    return self
  end
  
  return Map
end