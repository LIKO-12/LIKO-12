--Build DiskOS APIs--
_DiskVer = 2 --It's a global

function input()
  local t = ""
  
  local fw, fh = fontSize()
  local blink = false
  local blinktimer = 0
  local blinktime = 0.5
  local function drawblink()
    local cx,cy,c = printCursor() cy = cy-1
    rect(cx*(fw+1)-3,blink and cy*(fh+2)+2 or cy*(fh+2)+1,fw+1,blink and fh or fh+2,false,blink and 5 or c) --The blink
  end
  
  for event,a,b,c,d,e,f in pullEvent do
    if event == "textinput" then
      t = t .. a
      print(a,false)
    elseif event == "keypressed" then
      if a == "backspace" then
        blink = false; drawblink()
        if t:len() > 0 then printBackspace() end
        blink = true; drawblink()
        t = t:sub(0,-2)
      elseif a == "return" then
        blink = false; drawblink()
        return t --Return the text
      elseif a == "escape" then
        return false --User canceled text input.
      end
    elseif event == "update" then --Blink
      blinktimer = blinktimer + a
      if blinktimer > blinktime then
        blinktimer = blinktimer - blinktime
        blink = not blink
        drawblink()
      end
    end
  end
end

function SpriteSheet(img,w,h)
  local ss = {img=img,w=w,h=h} --SpriteSheet
  ss.cw, ss.ch, ss.quads = ss.img:width()/ss.w, ss.img:height()/ss.h, {}
  for y=1, ss.h do for x=1, ss.w do
    table.insert(ss.quads,ss.img:quad(x*ss.cw-(ss.cw-1),y*ss.ch-(ss.ch-1),ss.cw,ss.ch))
  end end
  
  function ss:image() return self.img end
  function ss:data() return self.img:data() end
  function ss:quad(id) return self.quads[id] end
  function ss:rect(id) local x,y,w,h = self.quads[id]:getViewport() return x+1,y+1,w,h end
  function ss:draw(id,x,y,r,sx,sy) self.img:draw(x,y,r,sx,sy,self.quads[id]) return self end
  function ss:extract(id) return imagedata(self.cw,self.ch):paste(self:data(),1,1,self:rect(id)) end
  
  return ss
end

function SpriteGroup(id,x,y,w,h,sx,sy,r,sheet)
  local sx,sy = math.floor(sx or 1), math.floor(sy or 1)
  if r then
    if type(r) ~= "number" then return error("R must be a number, provided: "..type(r)) end
    pushMatrix()
    cam("translate",x,y)
    cam("rotate",r)
    x,y = 0,0
  end
  for spry = 1, h or 1 do for sprx = 1, w or 1 do
    sheet:draw((id-1)+sprx+(spry*24-24),x+(sprx*sx*8-sx*8),y+(spry*sy*8-sy*8),0,sx,sy)
  end end
  if r then
    popMatrix()
  end
end

function isInRect(x,y,rect)
  if x >= rect[1] and y >= rect[2] and x <= rect[1]+rect[3]-1 and y <= rect[2]+rect[4]-1 then return true end return false
end

local debugGrids = false

function whereInGrid(x,y, grid) --Grid X, Grid Y, Grid Width, Grid Height, NumOfCells in width, NumOfCells in height
  local gx,gy,gw,gh,cw,ch = unpack(grid)
  
  if isInRect(x,y,{gx,gy,gw,gh}) then
    local clw, clh = math.floor(gw/cw), math.floor(gh/ch)
    local x, y = x-gx, y-gy
    local hx = math.floor(x/clw)+1 hx = hx <= cw and hx or hx-1
    local hy = math.floor(y/clh)+1 hy = hy <= ch and hy or hy-1
    if debugGrids then
      for x=1,cw do for y=1,ch do
        rect(gx+(x*clw-clw),gy+(y*clh-clh),clw,clh,true,9)
      end end
      rect(gx+(hx*clw-clw),gy+(hy*clh-clh),clw,clh,true,8)
    end
    return hx,hy
  end
  return false, false
end