
function Sprite(id,x,y,r,sx,sy,sheet) (sheet or SpriteMap):draw(id,x,y,r,sx,sy) end
function SpriteGroup(id,x,y,w,h,sx,sy,sheet)
  local sx,sy = math.floor(sx or 1), math.floor(sy or 1)
  for spry = 1, h or 1 do for sprx = 1, w or 1 do
    (sheet or SpriteMap):draw((id-1)+sprx+(spry*24-24),x+(sprx*sx*8-sx*8),y+(spry*sy*8-sy*8),0,sx,sy)
  end end
end

--Enter the while true loop and pull events, including the call of calbacks in _G
function eventLoop()
  while true do
    local name, a, b, c, d, e, f = pullEvent()
    if _G[name] and type(_G[name]) == "function" then
      _G[name](a,b,c,d,e,f)
    end
  end
end