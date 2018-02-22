--Copy a file from place to other
local args = {...} --Get the arguments passed to this program
if #args < 2 or args[1] == "-?" then
  printUsage(
    "cp <source> <destination>","Copies a file creating any missing directory in the destination path"
  )
  return
end

local term = require("terminal")
local source = term.resolve(args[1])
local destination = term.resolve(args[2])

color(8)

if not fs.exists(source) then return 1, "Source doesn't exists !" end

--Create destination folders
--Parse directories in the destination
local d, p = destination:match("(.+):/(.+)") --C:/./Programs/../Editors
p = ("/"..p.."/"):gsub("/","//"):sub(2,-1)
local dp, dirs = "", {}
for dir in string.gmatch(p,"/(.-)/") do
  dp = dp.."/"..dir
  table.insert(dirs,dp)
end

--Create the missing directories
for k, dir in ipairs(dirs) do
  if (not fs.exists(dir)) and not (fs.isFile(source) and k == #dirs) then
    if not pcall(fs.newDirectory,dir) then return 1, "Failed to create the destination folder" end
  elseif fs.exists(dir) and fs.isFile(dir) then
    if k < #dirs then
      return 1, "Can't copy inside a file !"
    elseif fs.isDirectory(source) then
      return 1, "Can't copy a directory into a file"
    end
  end
end

--Copy the source !
if fs.isFile(source) then
  fs.write(destination,fs.read(source))
  color(11) print("Copied file successfully")
else
  return 1, "Copying directories is not supported yet"
end