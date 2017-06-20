--Imports files--
--For now it imports images--

local source = select(1,...)
local destination = select(2,...)

local term = require("C://terminal")
local eapi = require("C://Editors")

local sw, sh = screenSize()

if source then source = term.resolve(source) end
if destination then destination = term.resolve(destination) end

if not source then color(8) print("Must provide path to the source file") return end
if not fs.exists(source) then color(8) print("Source doesn't exists") return end
if fs.isDirectory(source) then color(8) print("Source can't be a directory") return end
if destination then if fs.exists(destination) and fs.isDirectory(destination) then color(8) print("Destination must not be a directory") return end end
if destination then --Convert mode
  local imgd = imagedata(fs.read(source))
  fs.write(destination,imgd:encode())
  color(11) print("Converted Successfully")
else --Import to disk
  local imgd = imagedata(fs.read(source))
  local image = imagedata(sw,sh)
  image:paste(imgd)
  image = image:encode()
  eapi.leditors[3]:import(image..";\0;")
  color(11) print("Imported Successfully")
end
