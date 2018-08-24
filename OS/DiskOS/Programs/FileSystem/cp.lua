--Copy a file from place to other
local args = {...} --Get the arguments passed to this program
if #args < 2 or args[1] == "-?" then
  printUsage(
    "cp <source> <destination> [--verbose / -v]","Copies a file or directory, creating any missing directory in the destination path"
  )
  return
end

local function copyRecursive(from, to, verbose)
  color(10)
  if verbose then
    print("Copying " .. from .. " to " .. to)
  end
  if fs.isDirectory(from) then
    if fs.exists(to) then
      to = fs.combine(to, fs.getName(from))
    end
    local files = fs.getDirectoryItems(from)
    for _,file in ipairs(files) do
      copyRecursive(
        fs.combine(from, file),
        fs.combine(to, file),
        verbose
      )
    end
  else
    local data = fs.read(from)
    fs.write(to, data)
  end
end

local term = require("terminal")
local source = term.resolve(args[1])
local destination = term.resolve(args[2])
local verbose = args[3] == "--verbose" or args[3] == "-v"

color(8)

if not fs.exists(source) then return 1, "Source doesn't exists !" end
if fs.isReadonly(destination) then return 1, "Destination is readonly !" end

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
copyRecursive(source, destination, verbose)
color(11)
print("Successfully Copied!")
