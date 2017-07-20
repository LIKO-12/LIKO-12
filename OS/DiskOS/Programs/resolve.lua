--Resolves the given path, and prints the result
local args = {...}
if args[1] and args[1] == "-?" then
  printUsage("resolve <path>","Resolves the path and prints it")
end

local term = require("terminal")
local path = term.resolve(table.concat(args," "))
print(path)