local path = ...

local strformat = string.format

local function newMap(w,h,sheet)
  local Map = {}
  
  Map.w, Map.h = w or 24, h or 9
  --Initialize the map table
  Map.m = {}
  for x=0, Map.w-1 do
    Map.m[x] = {}
    for y=0, Map.h-1 do
      Map.m[x][y] = 0
    end
  end
  Map.sheet = sheet

  --If called with a function, it will be called on everycell with x,y,sprid args
  --The function can return an new sprid to set
  --If called with no args, it will return the map table.
  function Map:map(func,x,y,w,h)
    x,y,w,h = x or 0, y or 0, w or self.w, h or self.h
    
    assert(x >= 0, "Attempted to map out of bounds: x less than 0 ("..x..")")
    assert(y >= 0, "Attempted to map out of bounds: y less than 0 ("..y..")")
    assert(x+w <= self.w, "Attempted to map out of bounds: right side greater than map width (Width is "..self.w..", right side is "..x+w..")")
    assert(y+h <= self.h, "Attempted to map out of bounds: lower side greater than map height (Height is "..self.h..", lower side is "..y+h..")")
	
    if func then
      for iy=y, y+h-1 do
        for ix=x, x+w-1 do
          self.m[ix][iy] = func(ix,iy,self.m[ix][iy]) or self.m[ix][iy]
        end
      end
    end
    return self.m
  end

  function Map:cell(x,y,newID)
    if x >= self.w or y >= self.h or x < 0 or y < 0 then return false, "out of range" end
    if newID then
      self.m[x][y] = newID or 0
      if self.batch then
        self.batch:set(1+x+y*self.w,self.sheet.quads[newID or 0],x*8,y*8)
      end
      return self
    else
      return self.m[x][y]
    end
  end
  
  function Map:cut(x,y,w,h)
    local x,y,w,h = math.floor(x or 0), math.floor(y or 0), math.floor(w or self.w), math.floor(h or self.h)
    local nMap = newMap(w,h,self.sheet)
    local m = nMap:map()
    for my=y, y+h-1 do
      for mx=x, x+w-1 do
        if self.m[mx] and self.m[mx][my] then
          m[mx-x][my-y] = self.m[mx][my]
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
    
    --Spritebatch mode draws the whole map
    if self.batch then
      self.batch:draw(dx,dy)
      return self
    end

	  --mapX and mapY are different from x and y so that if x or y are less
    --than 0, the clamping doesn't affect the relative position of
    --the tiles on the screen.
    local mapX = math.max(x,0)
    local mapY = math.max(y,0)
    w = math.min(w+x,self.w)-x
    h = math.min(h+y,self.h)-y
    
    self:map(function(spx,spy,sprid)
      if sprid < 1 then return end
      
      spx, spy = spx-x, spy-y;
	  
      (self.sheet or sheet):draw(sprid,dx + spx*8*sx, dy + spy*8*sy, 0, sx, sy)
    end,mapX,mapY,w,h)
    return self
  end
  
  function Map:export()
    local data = {strformat("LK12;TILEMAP;%dx%d;",self.w,self.h)}
    local datalen = 2
    self:map(function(x,y,sprid)
      if x == 0 then
        data[datalen] = "\n"
        datalen = datalen + 1
      end
      data[datalen] = sprid
      data[datalen+1] = ";"
      datalen = datalen+2
    end)
    return table.concat(data)
  end
  
  function Map:import(data)
    if not data:sub(1,13) == "LK12;TILEMAP;" then error("Wrong header") end
    data = data:gsub("\n","")
    local w,h,mdata = string.match(data,"LK12;TILEMAP;(%d+)x(%d+);(.+)")
    local nextid = mdata:gmatch("(.-);")
    self:map(function(x,y,sprid)
      return 0
    end)
    
    for y=0,h-1 do
      for x=0,w-1 do
        self:cell(x,y,tonumber(nextid() or "0"))
      end
    end
    
    return self
  end

  function Map:spritebatch(mode)
    if self.batch then return error("Already spritebatched !") end
    if not self.sheet then return error("The map has no spritesheet !") end

    self.batch = self.sheet.img:batch(self.w*self.h,mode)
    for y=0, self.h-1 do for x=0, self.w-1 do
      self.batch:add(self.sheet.quads[self:cell(x,y)],x*8,y*8)
    end end
  end
  
  return Map
end

return newMap