--Remove/delete a specific file
local args = {...} --Get the arguments passed to this program
if #args < 1 or args[1] == "-?" then
  printUsage(
    "rm <files/directory>","Deletes the file/directory"
  )
  return
end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("terminal")

local function index(path,notfirst)
  color(9)
  if fs.isFile(path) then print("Deleted "..path) fs.delete(path) return end
  local items = fs.getDirectoryItems(path)
  for k, item in ipairs(items) do
    if fs.isDirectory(path..item) then
      print("Entering directory "..path..item.."/") pullEvent()
      index(path..item.."/",true)
    else
      print("Deleted "..path..item) pullEvent()
      fs.delete(path..item)
    end
  end
  local isDir = fs.isDirectory(path)
  fs.delete(path)
  if not notfirst then color(11) print("Deleted "..(isDir and "Directory" or "File").." successfully") end
  return true
end

tar = term.resolve(tar)

if not fs.exists(tar) then return 1, "Path doesn't exist" end
if fs.isReadonly(tar) then return 1, "Path is readonly !" end

index(fs.isFile(tar) and tar or tar.."/")