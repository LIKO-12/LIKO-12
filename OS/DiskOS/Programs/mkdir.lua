--Create a new directory/folder
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(9) print("\nMust provide the directory name") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
print("") --A new line

tar = term.parsePath(tar)

local ok, err = pcall(fs.newDirectory,tar)
if ok then
  color(12) print("Created directory successfully")
else
  color(9) print(err or "Failed to create directory")
end