local tw, th = termSize()

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

local apilist = {}

do
  local list = apilist
  for k,v in pairs(_G) do
    if type(v) ~= "table" then table.insert(list,k) end
  end
  
  local function add(...)
    for k,v in ipairs({...}) do
      table.insert(list,v)
    end
  end
  
  add("dofile","printUsage","getAPI")
  add("bump","class","lume","JSON","luann","geneticAlgo","vector")
  add("Sprite","fget","fset","map","eventLoop","pget","pset","sget","sset","mget","mset","Controls","SFX","SaveID","SaveData","LoadData")
  add("SpriteMap","SheetFlagsData","TileMap","MapObj","SFXS","SfxObj","_GameCode","btn","btnp","__BTNUpdate","__BTNKeypressed","__BTNTouchControl","_BTNGamepad","_DISABLE_PAUSE")
end

function getAPI()
  return apilist
end

class = require("Libraries.middleclass")