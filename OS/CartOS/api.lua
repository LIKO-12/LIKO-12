--Build CartOS APIs--
function SpriteSheet(img,w,h)
  local ss = {img=img,w=w,h=h} --SpriteSheet
  ss.cw, ss.ch, ss.quads = ss.img:width()/ss.w, ss.img:height()/ss.h, {}
  for y=1, ss.h do for x=1, ss.w do
    table.insert(ss.quads,ss.img:quad(x*ss.cw-(ss.cw-1),y*ss.ch-(ss.ch-1),ss.cw,ss.ch))
  end end
  
  function ss.image() return ss.img end
  function ss.data() return ss.img:data() end
  function ss.quad(id) return ss.quads[id] end
  function ss.rect(id) local x,y,w,h = ss.quads[id]:getViewport() return x+1,y+1,w,h end
  function ss.draw(id,x,y,r,sx,sy) ss.img.draw(x,y,r,sx,sy,self.quads[id]) return self end
  function ss.extract(id) return imagedata(8,8).paste(ss.data(),1,1,ss.rect(id)) end
  
  return ss
end

function isInRect(x,y,rect)
  if x >= rect[1] and y >= rect[2] and x <= rect[1]+rect[3] and y <= rect[2]+rect[4] then return true end return false
end

function whereInGrid(x,y, grid) --Grid X, Grid Y, Grid Width, Grid Height, NumOfCells in width, NumOfCells in height
  local gx,gy,gw,gh,cw,ch = unpack(grid)
  if isInRect(x,y,{gx,gy,gw,gh}) then
    local clw, clh = math.floor(gw/cw), math.floor(gh/ch)
    local x, y = x-gx, y-gy
    local hx = math.floor(x/clw)+1 hx = hx <= cw and hx or hx-1
    local hy = math.floor(y/clh)+1 hy = hy <= ch and hy or hy-1
    return hx,hy
  end
  return false, false
end