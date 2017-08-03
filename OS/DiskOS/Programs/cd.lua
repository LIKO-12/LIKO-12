--Enter a specifiec directory/path/drive
local args = {...} --Get the arguments passed to this program
if #args < 1 or args[1] == "-?" then
  printUsage(
    "cd <directory>", "Change Directory",
    "cd ..", "Go back one directory",
    "cd <drive>:", "Change active drive"
  )
  return
end

local tar = table.concat(args," ") --The path may include whitespaces
local term = require("terminal")

tar = term.resolve(tar)

local ok, err = pcall(term.setpath,tar)
if not ok then
  color(8) print(tostring(err))
end