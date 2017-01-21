--Remove/delete a specific file
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(9) print("\nMust provide the path") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
print("") --A new line

local function index(path,notfirst)
  color(8)
  if fs.isFile(path) then print("Deleted "..path) fs.remove(path) return end
  local items = fs.directoryItems(path)
  for k, item in ipairs(items) do
    if fs.isDirectory(path..item) then
      print("Entering directory "..path..item.."/",true)
      index(path..item.."/")
    else
      print("Deleted "..path..item)
      fs.remove(path..item)
    end
  end
  fs.remove(path)
  if not notfirst then print("Deleted File/s successfully") end
  return true
end

local d, p = tar:match("(.+)://(.+)")
if d and p then if fs.exists(tar) then index(tar) end return end
local d = tar:match("/(.+)")
if d then if fs.exists(term.getdrive().."://"..tar) then index(term.getdrive().."://"..tar) end return end
if fs.exists(term.getpath()..tar) then
  index(term.getpath()..(tar:sub(-2,-1) == "/" and tar or tar.."/"))
  return
end
color(9) print("Path doesn't exists")