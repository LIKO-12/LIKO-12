--Enter a specifiec directory/path/drive
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(9) print("\nMust provide the path") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
print("") --A new line
local d, p = tar:match("(.+)://(.+)")
if d then term.setpath(tar) return end
local d = tar:match("(.+):") --ex: cd D:
if d then term.setpath(d..":///") return end
local d = tar:match("/(.+)")
if d then term.setdirectory(tar) return end
if tar == ".." then
  local fld = {} --A list of folders in the path
  for p in string.gmatch(term.getdirectory(),"/(.+)/") do
    table.insert(fld,p)
  end
  if #fld == 0 then return end
  table.remove(fld, #fld)
  term.setdirectory("/"..table.concat(fld,"/"))
  return
end
term.setdirectory(term.getdirectory()..tar)
