--Lists the folders and files at the current directory.
local term = require("C://terminal") --Require the terminal api.
local path = term.getpath() --Get the current active directory.
local files = fs.directoryItems(path) --Returns a table containing the names of folders and files in the given directory
print("") --A new line
for k, f in ipairs(files) do
  color(fs.isFile(path..f) and 8 or 12)
  print(f.." ",false)
end
print("")