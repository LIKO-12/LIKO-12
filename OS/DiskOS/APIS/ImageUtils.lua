--ImageUtils, useful functions foe use when processing imagedatas.

--Localized Lua Library

--The API
local ImageUtils = {}

--A queued fill algorithm.
function ImageUtils.queuedFill(img,sx,sy,rcol,minx,miny,maxx,maxy)
  
  local get = img.getPixel
  local set = img.setPixel
  
  local tcol = get(img,sx,sy) --The target color
  
  if tcol == rcol then return end
  
  --Queue, QueueSize, QueuePosition
  local q, qs, qp = {}, 0,0
  
  set(img,sx,sy,rcol)
  qs = qs + 1
  q[qs] = {sx,sy}
  
  local function test(x,y)
    if minx and (x < minx or y < miny or x > maxx or y > maxy) then return end
    if get(img,x,y) == tcol then
      set(img,x,y,rcol)
      qs = qs + 1
      q[qs] = {x,y}
    end
  end
  
  while qp < qs do --While there are items in the queue.
    
    qp = qp + 1
    
    local n = q[qp]
    local x,y = n[1], n[2]
    
    test(x-1,y) test(x+1,y)
    test(x,y-1) test(x,y+1)
    
  end
  
end

--Make the ImageUtils a global
_G["ImageUtils"] = ImageUtils