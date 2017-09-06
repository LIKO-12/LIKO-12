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
        line = "\n  "..line.."\n"
      end
      color(6)
      print(line)
    end
  end
end

function dofile(path,...)
  local chunk, err = fs.load(path)
  if not chunk then return error(tostring(err)) end
  local args = {pcall(chunk,...)}
  if not args[1] then return error(tostring(args[2])) end
  for k,v in ipairs(args) do
    if k > 1 then
      args[k-1] = v
    end
  end
  return unpack(args)
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
  add("bump","class","lume")
  add("Sprite","fget","fset","map","eventLoop","pget","pset","sget","sset","mget","mset","Controls")
  add("SpriteMap","SheetFlagsData","TileMap","MapObj","btn","btnp","__BTNUpdate","__BTNKeypressed","__BTNTouchControl","_BTNGamepad")
end

function getAPI()
  return apilist
end

class = require("Libraries.middleclass")