--Imports files--
--For now it imports images--

local source = select(1,...)
local destination = select(2,...)

local term = require("C://terminal")

if source then source = term.parsePath(source) end
if destination then destination = term.parsePath(destination) end

print("") --New line

if not source then color(9) print("Must provide path to the source file") return end
if not fs.exists(source) then color(9) print("Source doesn't exists") return end
if fs.isDirectory(source) then color(9) print("Source can't be a directory") return end
if destination then if fs.exists(destination) and fs.isDirectory(destination) then color(9) print("Destination must not be a directory") return end end
if destination then --Convert mode
  local imgd = imagedata(fs.read(source))
  fs.write(destination,imgd:encode())
else --Import to disk
  color(9) print("Sorry, importing to the disk is not supported yet")
end