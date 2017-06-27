--Remove/delete a specific file
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(8) print("Must provide the path") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")

local function index(path,notfirst)
  color(9)
  if fs.isFile(path) then print("Deleted "..path) fs.remove(path) return end
  local items = fs.directoryItems(path)
  for k, item in ipairs(items) do
    if fs.isDirectory(path..item) then
      print("Entering directory "..path..item.."/")
      index(path..item.."/",true)
    else
      print("Deleted "..path..item)
      fs.remove(path..item)
    end
  end
  fs.remove(path)
  if not notfirst then color(11) print("Deleted File/s successfully") end
  return true
end

local tarExists; tar, tarExists = term.resolve(tar)

if not tarExists then color(8) print("Path doesn't exists") return end

index(tar)