--DiskOS Globals: All the global variables DiskOS has:
--[[ Peripherals:
- The GPU, CPU, Keyboard and RAM has their functions available as globals.
- All the peripherals are available in global tables.
- The HDD peripheral is also available as fs, use fs instead of HDD !
]]

--[[ Version:
- _LIKO_Version, LIKO-12's current version string.
- _LIKO_Old, LIKO-12's old version string,
- _LVer, Parsed LIKO-12 version information, a table with this indexes: major,minor,patch and tag.
]]

--[[ Constants:
- _APIVer, The current version of the games API.
- _APIList, A list
- _SystemDrive, The drive system is running from.
- _SystemSheet, The system sprites sheet.
]]

--[[ Sprites Functions:
- SpriteGroup: For drawing sprites bigger than 8x8 from a SpriteSheet.
]]

--[[ UI Functions:
- Those are handy functions that I use when I'm writing UI related code.
- isInRect(x,y,rect), whereInGrid(x,y,grid)
]]

--[[ Miscellaneous:
- printUsage(...): for printing programs usages.
]]

--==Variables used by the global functions==--
local tw, th = termSize()
local SpriteSheet = require("Libraries.spritesheet")

--==Version==--

_LIKO_Version, _LIKO_Old = BIOS.getVersion()
_LVer = {}
_LVer.major, _LVer.minor, _LVer.patch, _LVer.tag = string.match(_LIKO_Version,"(%d+)%.(%d+)%.(%d+)%-(.+)")
_LVer.major, _LVer.minor, _LVer.patch = tonumber(_LVer.major), tonumber(_LVer.minor), tonumber(_LVer.patch)

--==Constants==--

_APIVer = 2 --The current version of the games API.
_APIList = {} --An array containing LIKO-12's global API names (Used by the syntax parser).

do
  local list = _APIList
  for k,v in pairs(_G) do
    if type(v) ~= "table" then list[#list+1] = k end
  end
  
  local function add(...)
    for k,v in ipairs({...}) do
      table.insert(list,v)
    end
  end
  
  add("dofile","printUsage","_APIVer","Library")
  add("Sprite","fget","fset","map","eventLoop","pget","pset","sget","sset","mget","mset","Controls","SFX","SaveID","SaveData","LoadData")
  add("SpriteMap","SheetFlagsData","TileMap","MapObj","SFXS","SfxObj","_GameCode","btn","btnp","__BTNUpdate","__BTNKeypressed","__BTNTouchControl","_BTNGamepad","_DISABLE_PAUSE")
  add("SpriteGroup","isInRect","whereInGrid","input")
end

_SystemDrive = fs.drive()
_GameDiskOS = (_SystemDrive == "GameDiskOS")
_SystemSheet = SpriteSheet(image(fs.read(_SystemDrive..":/systemsheet.lk12")),24,16)

--==Sprites Functions==--

function SpriteGroup(id,x,y,w,h,sx,sy,r,sheet)
  local sx,sy = math.floor(sx or 0), math.floor(sy or 0)
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

--==UI Functions==--

function isInRect(x,y,rect)
  if x >= rect[1] and y >= rect[2] and x <= rect[1]+rect[3]-1 and y <= rect[2]+rect[4]-1 then return true end return false
end

function whereInGrid(x,y, grid) --Grid X, Grid Y, Grid Width, Grid Height, NumOfCells in width, NumOfCells in height
  local gx,gy,gw,gh,cw,ch = grid[1], grid[2], grid[3], grid[4], grid[5], grid[6]
  
  if isInRect(x,y,{gx,gy,gw,gh}) then
    local clw, clh = math.floor(gw/cw), math.floor(gh/ch)
    local x, y = x-gx, y-gy
    local hx = math.floor(x/clw)+1 hx = hx <= cw and hx or hx-1
    local hy = math.floor(y/clh)+1 hy = hy <= ch and hy or hy-1
    return hx,hy
  end
  return false, false
end

--==Miscellaneous Functions==--

function printUsage(...)
  local t = {...}
  color(9)
  if #t > 2 then print("Usages:") else print("Usage:") end
  for k, line in ipairs(t) do
    if k%2 == 1 then
      color(7)
      print(line,false)
    else
      local pre = t[k-1]
      local prelen = pre:len()
      local suflen = line:len()
      local toadd = tw - (prelen+suflen)
      if toadd > 0 then
        line = string.rep(" ",toadd)..line
      else
        line = "\n  "..line
      end
      color(6)
      print(line)
    end
  end
end