--Copy a file from place to other
--This is an alies of cp.lua

local args = {...} --Get the arguments passed to this program
if #args < 2 or args[1] == "-?" then
  printUsage(
    "copy <source> <destination>","Copies a file creating any missing directory in the destination path"
  )
  return 0
end

local term = require("terminal")
return term.execute("cp",...)