--Create a new directory/folder
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(9) print("\nMust provide the directory name") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
print("") --A new line
local d, p = tar:match("(.+)://(.+)")
if d and p then fs.newDirectory(tar) color(12) print("Created directory successfully") return end
local d = tar:match("/(.+)")
if d then fs.newDirectory(term.getdrive().."://"..tar) color(12) print("Created directory successfully") return end
fs.newDirectory(term.getpath()..tar)
color(12) print("Created directory successfully")