--Create a new directory/folder
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(8) print("Must provide the directory name") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")

tar = term.resolve(tar)

local ok, err = pcall(fs.newDirectory,tar)
if ok then
  color(11) print("Created directory successfully")
else
  color(8) print(err or "Failed to create directory")
end