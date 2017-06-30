function Sprite(id,x,y,r,sx,sy,sheet) (sheet or SpriteMap):draw(id,x,y,r,sx,sy) end
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
    (sheet or SpriteMap):draw((id-1)+sprx+(spry*24-24),x+(sprx*sx*8-sx*8),y+(spry*sy*8-sy*8),0,sx,sy)
  end end
  if r then
    popMatrix()
  end
end

--Flags API
function fget(id,n)
  if type(id) ~= "number" then return error("SpriteId must be a number, provided: "..type(id)) end
  if n and type(n) ~= "number" then return error("BitNumber must be a number, provided: "..type(n)) end
  local id = math.floor(id)
  local n = n; if n then n = math.floor(n) end
  local flags = SheetFlagsData or string.char(0)
  if type(flags) ~= "string" or flags:len() == 0 then return error("Corrupted SheetFlagsData") end
  if id < 1 then return error("SpriteId is out of range ("..id..") expected [1,"..flags:len().."]") end
  if id > flags:len() then return error("SpriteId is out of range ("..id..") expected [1,"..flags:len().."]") end
  local flag = string.byte(flags:sub(id,id))
  if n then
    if n < 1 then return error("BitNumber is out of range ("..n..") expected [1,8]") end
    if n > 8 then return error("BitNumber is out of range ("..n..") expected [1,8]") end
    n = n-1
    n = (n==0) and 1 or (2^n)
    return bit.band(flag,n) == n
  else
    return flag
  end
end

function fset(id,n,v)
  if type(id) ~= "number" then return error("SpriteId must be a number, provided: "..type(id)) end
  local id = math.floor(id)
  
  local flags = SheetFlagsData or string.char(0)
  if type(flags) ~= "string" or flags:len() == 0 then return error("Corrupted FlagsData") end
  
  if id < 1 then return error("SpriteId is out of range ("..id..") expected [1,"..flags:len().."]") end
  if id > flags:len() then return error("SpriteId is out of range ("..id..") expected [1,"..flags:len().."]") end
  local flag = string.byte(flags:sub(id,id))
  
  if type(v) == "boolean" then
    if type(n) ~= "number" then return error("BitNumber must be a number, provided: "..type(n)) end
    n = math.floor(n)
    if n < 1 then return error("BitNumber is out of range ("..n..") expected [1,8]") end
    if n > 8 then return error("BitNumber is out of range ("..n..") expected [1,8]") end
    if type(v) ~= "boolean" and type(v) ~= "nil" then return error("BitValue must be a boolean") end
    n = n-1
    n = (n==0) and 1 or (2^n)
    if v then
      flag = bit.bor(flag,n)
    else
      n = bit.bnot(n)
      flag = bit.band(flag,n)
    end
    SheetFlagsData = flags:sub(0,id-1)..string.char(flag)..flags:sub(id+1,-1)
  else
    if type(n) ~= "number" then return error("FlagValue must be a number") end
    n = math.floor(n)
    if n < 1 then return error("FlagValue is out of range ("..n..") expected [1,255]") end
    if n > 255 then return error("FlagValue is out of range ("..n..") expected [1,255]") end
    flag = string.char(n)
    SheetFlagsData = flags:sub(0,id-1)..flag..flags:sub(id+1,-1)
  end
end

function map(...)
 if not TileMap then return error("TileMap Global is lost") end
 local ok, err = pcall(TileMap.draw,TileMap,...)
 if not ok then return error(err) end
end

--Enter the while true loop and pull events, including the call of calbacks in _G
function eventLoop()
  while true do
    local name, a, b, c, d, e, f = pullEvent()
    if _G["_"..name] and type(_G["_"..name]) == "function" then
      _G["_"..name](a,b,c,d,e,f)
    end
    if name == "update" and _G["_draw"] and type(_G["_draw"]) == "function" then
      _G["_draw"](a,b,c,d,e,f)
    end
  end
end

local bmap = {
  {"left","right","up","down","z","x"}, --Player 1
  {"s","f","e","d","tab","q"} --Player 2
}