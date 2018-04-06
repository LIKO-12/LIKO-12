--Lists the folders and files at the current directory.
--The same of dir.lua

if select(1,...) == "-?" then
  printUsage(
    "ls","Lists the files and folders in the current directory",
    "ls <dir>","Lists the files and folders in a specific directory"
  )
  return
end

local term = require("terminal") --Require the terminal api.
local path = term.getpath() --Get the current active directory.
local dir = select(1,...) 

if dir then
	local newpath, exists = term.resolve(dir)
	if not exists then return 1, "Folder doesn't exists !" end
	if not fs.isDirectory(newpath) then return 1, "It should be a folder, provided a file !" end
	path = newpath.."/"
end

local files = fs.getDirectoryItems(path) --Returns a table containing the names of folders and files in the given directory

for k, f in ipairs(files) do
  color(fs.isFile(path..f) and 6 or 11)
  print(f.." ",false)
end
print("")
