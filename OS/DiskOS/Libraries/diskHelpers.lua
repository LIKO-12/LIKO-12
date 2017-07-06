--SpriteID, Top-left x, Top-left y, rotation in radians, scaleX, scaleY, spritesheet
function Sprite(id,x,y,r,sx,sy,sheet) (sheet or SpriteMap):draw(id,x,y,r,sx,sy) end

--Topleft SpriteID, Top-left x, Top-left y, group width in sprites, group height in sprites, scaleX, scaleY, rotatin in radian, spritesheet
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
--SpriteID, [bit number] (Note: currently bits are numbered from left to right)
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

--SpriteID, bit number (Note: currently bits are numbered from left to right), new value
--SpriteID, new byte value
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

--DrawX, DrawY, Top-left map cell, Top-left map cell, Map width in cells, Map height in cells, scaleX,scaleY, spritesheet
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
    
    if name == "keypressed" then
      __BTNKeypressed(a,c)
    elseif name == "update" then
      __BTNUpdate(a)
    end
  end
end

--Get and set functions for lazy people
--ScreenPixels--
local sw, sh = screenSize()
local VRAMLine = sw/2
local firstNibble, lastNibble = tonumber(1111,2), tonumber(11110000,2)

function pget(x,y)
  if type(x) ~= "number" then return error("X must be a number, provided: "..type(x)) end
  if type(y) ~= "number" then return error("Y must be a number, provided: "..type(y)) end
  x, y = math.floor(x), math.floor(y)
  if x < 0 or x > sw-1 then return error("X out of range ("..x.."), must be [0,"..(sw-1).."]") end
  if y < 0 or y > sh-1 then return error("Y out of range ("..y.."), must be [0,"..(sh-1).."]") end
  
  local odd = (x%2 == 1)
  if odd then x = x-1 end
  
  local address = 0x15000 + y*VRAMLine + x/2
  local byte = peek(address)
  if odd then
    local bits = bit.band(byte,lastNibble)
    bits = bit.rshift(bits,4)
    return bits
  else
    return bit.band(byte,firstNibble)
  end
end

function pset(x,y,col)
  if type(x) ~= "number" then return error("X must be a number, provided: "..type(x)) end
  if type(y) ~= "number" then return error("Y must be a number, provided: "..type(y)) end
  if type(col) ~= "number" then return error("Color must be a number, provided: "..type(col)) end
  x, y, col = math.floor(x), math.floor(y), math.floor(col)
  if x < 0 or x > sw-1 then return error("X out of range ("..x.."), must be [0,"..(sw-1).."]") end
  if y < 0 or y > sh-1 then return error("Y out of range ("..y.."), must be [0,"..(sh-1).."]") end
  if col < 0 or col > 15 then return error("Color out of range ("..col.."), must be [0,15]") end
  
  local odd = (x%2 == 1)
  if odd then x = x-1 end
  
  local address = 0x15000 + y*VRAMLine + x/2
  local byte = peek(address)
  if odd then
    byte = bit.band(byte,firstNibble)
    col = bit.lshift(col,4)
    byte = bit.bor(byte,col)
  else
    byte = bit.band(byte,lastNibble)
    byte = bit.bor(byte,col)
  end
  poke(address,byte)
end

--Map cells--
local mapw, maph = TileMap:size()
function mget(x,y)
  if type(x) ~= "number" then return error("X must be a number, provided: "..type(x)) end
  if type(y) ~= "number" then return error("Y must be a number, provided: "..type(y)) end
  x, y = math.floor(x), math.floor(y)
  if x < 0 or x > mapw-1 then return error("X out of range ("..x.."), must be [0,"..(mapw-1).."]") end
  if y < 0 or y > maph-1 then return error("Y out of range ("..y.."), must be [0,"..(maph-1).."]") end
  return TileMap:cell(x,y)
end

function mset(x,y,id)
  if type(x) ~= "number" then return error("X must be a number, provided: "..type(x)) end
  if type(y) ~= "number" then return error("Y must be a number, provided: "..type(y)) end
  if type(id) ~= "number" then return error("TileID must be a number, provided: "..type(id)) end
  x, y, id = math.floor(x), math.floor(y), math.floor(id)
  if x < 0 or x > mapw-1 then return error("X out of range ("..x.."), must be [0,"..(mapw-1).."]") end
  if y < 0 or y > maph-1 then return error("Y out of range ("..y.."), must be [0,"..(maph-1).."]") end
  if id < 0 or id > 255 then return error("TileID out of range ("..id.."), must be [0,255]") end
  TileMap:cell(x,y,id)
end