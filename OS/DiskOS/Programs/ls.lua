--Lists the folders and files at the current directory.
--The same of dir.lua

if select(1,...) == "-?" then
  printUsage(
    "ls","Lists the files and folders in the current directory"
  )
  return
end

local term = require("C://terminal") --Require the terminal api.
local dir = select(1,...) or ""
local path = term.getpath() --Get the current active directory.
if dir then path = path .. "/" .. dir .. "/" end
local files = fs.directoryItems(path) --Returns a table containing the names of folders and files in the given directory

for k, f in ipairs(files) do
  color(fs.isFile(path..f) and 7 or 11)
  print(f.." ",false)
end
print("")