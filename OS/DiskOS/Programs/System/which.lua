--Searches for the give command, and prints the program location
local args = {...}
if #args < 1 or args[1] == "-?" then
  printUsage("which <path>","Searches from the terminal runs this command, and prints the path to it.")
  return
end

local program = args[1]

local term = require("terminal")
local curpath = term.getpath()

if fs.isFile(curpath..program..".lua") then
  color(6) print(curpath..program..".lua")
  return 0
end

local PATH = term.getPATH()
for path in string.gmatch(PATH,"(.-);") do
  if fs.exists(path) then
    local files = fs.getDirectoryItems(path)
    for id,file in ipairs(files) do
      if file == program..".lua" and fs.isFile(path..file) then
        color(6) print(path..file)
        return 0
      end
    end
  end
end

color(8) print("Can't find command '"..program.."'")