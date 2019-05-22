--Imports files--
--For now it imports images--
local source = select(1,...)
local destination = select(2,...)

local term = require("terminal")
local eapi = require("Editors")

local sw, sh = screenSize()

if not source or source == "-?" then
  printUsage(
    "import <image>","Imports an image (gif, jpg, png)",
    "import <image> <destination>","Converts an image to a .lk12 image file",
    "import @label","Import the label image",
    "import @label <destination>","Converts the label image to a .lk12 image file"
  )
  return
end

if source ~= "@label" then
  source = term.resolve(source)
end

if destination then destination = term.resolve(destination) end

if source ~= "@label" then
  if not fs.exists(source) then return 1, "Source doesn't exist" end
  if fs.isDirectory(source) then return 1, "Source can't be a directory" end
end

if destination then
  if fs.exists(destination) and fs.isDirectory(destination) then return 1, "Destination must not be a directory" end
  if fs.isReadonly(destination) then return 1, "Destination is readonly !" end
end

if destination then --Convert mode
  local imgd = (source == "@label") and getLabelImage() or imagedata(fs.read(source))
  fs.write(destination,imgd:encode())
  color(11) print("Converted Successfully")
else --Import to disk
  local imgd = (source == "@label") and getLabelImage() or imagedata(fs.read(source))
  local image = imagedata(sw,sh)
  image:paste(imgd)
  image = image:encode()
  eapi.leditors[eapi.editors.sprite]:import(image..";\0;")
  color(11) print("Imported Successfully")
end
