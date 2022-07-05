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

--Play a sfx
function SFX(id,chn)
  if (not SFXS) or (not SFXS[id]) then return error("SFX "..tostring(id).." doesn't exist!") end
  
  SFXS[id]:play(chn)
end

--Flags API
--SpriteID, [bit number]
function fget(id,n)
  if type(id) ~= "number" then return error("SpriteId must be a number, provided: "..type(id)) end
  if n and type(n) ~= "number" then return error("BitNumber must be a number, provided: "..type(n)) end
  local id = math.floor(id)
  local n = n; if n then n = math.floor(n) end
  local sheet = SpriteMap
  if id < 0 then return error("SpriteId is out of range ("..id..") expected [0,"..#sheet.quads.."]") end
  if id > #sheet.quads then return error("SpriteId is out of range ("..id..") expected [0,"..#sheet.quads.."]") end
  if id == 0 then return end
  local flag = sheet:flag(id)
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

--SpriteID, bit number new value
--SpriteID, new byte value
function fset(id,n,v)
  if type(id) ~= "number" then return error("SpriteId must be a number, provided: "..type(id)) end
  local id = math.floor(id)
  
  local sheet = SpriteMap
  
  if id < 1 then return error("SpriteId is out of range ("..id..") expected [1,"..#sheet.quads.."]") end
  if id > #sheet.quads then return error("SpriteId is out of range ("..id..") expected [1,"..#sheet.quads.."]") end
  local flag = sheet:flag(id)
  
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
  else
    if type(n) ~= "number" then return error("FlagValue must be a number") end
    n = math.floor(n)
    if n < 1 then return error("FlagValue is out of range ("..n..") expected [1,255]") end
    if n > 255 then return error("FlagValue is out of range ("..n..") expected [1,255]") end
	flag = n
  end
  sheet:flag(id,flag)
end

--DrawX, DrawY, Top-left map cell, Top-left map cell, Map width in cells, Map height in cells, scaleX,scaleY, spritesheet
function map(...)
 if not TileMap then return error("TileMap Global is lost") end
 local ok, err = pcall(TileMap.draw,TileMap,...)
 if not ok then return error(err) end
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

--Spritesheet pixels--
function sget(x,y)
  if type(x) ~= "number" then return error("X must be a number, provided: "..type(x)) end
  if type(y) ~= "number" then return error("Y must be a number, provided: "..type(y)) end
  x, y = math.floor(x), math.floor(y)
  if x < 0 or x > sw-1 then return error("X out of range ("..x.."), must be [0,"..(sw-1).."]") end
  if y < 0 or y > sh-1 then return error("Y out of range ("..y.."), must be [0,"..(sh-1).."]") end
  return SpriteMap.img:data():getPixel(x,y)
end

function sset(x,y,col)
  if type(x) ~= "number" then return error("X must be a number, provided: "..type(x)) end
  if type(y) ~= "number" then return error("Y must be a number, provided: "..type(y)) end
  if type(col) ~= "number" then return error("Color must be a number, provided: "..type(col)) end
  x, y, col = math.floor(x), math.floor(y), math.floor(col)
  if x < 0 or x > sw-1 then return error("X out of range ("..x.."), must be [0,"..(sw-1).."]") end
  if y < 0 or y > sh-1 then return error("Y out of range ("..y.."), must be [0,"..(sh-1).."]") end
  if col < 0 or col > 15 then return error("Color out of range ("..col.."), must be [0,15]") end
  SpriteMap.img = SpriteMap.img:data():setPixel(x,y):image()
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

function Controls(c)
  local c = c or "gamepad"
  if c == "gamepad" then
    TC.setInput(true)
    textinput(not isMobile())
  elseif c == "keyboard" then
    TC.setInput(false)
    textinput(true)
  elseif c == "touch" or c == "mouse" then
    TC.setInput(false)
    textinput(false)
  elseif c == "none" then
    TC.setInput(false)
    textinput(false)
  end
end

function exit(failReason)
  coroutine.yield("RUN:exit", failReason)
end