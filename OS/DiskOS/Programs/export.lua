local destination = select(1,...)

local term = require("C://terminal")
local eapi = require("C://Editors")

if not destination then color(8) print("Must provide the destination file path") return end

destination = term.resolve(destination)

if fs.exists(destination) and fs.isDirectory(destination) then color(8) print("Destination must not be a directory") return end

if destination:sub(-4,-1) == ".png" then --Sprite Map Exporting.
  if select(2,...) == "-opaque" then
    fs.write(destination,eapi.leditors[3].SpriteMap.img:data():exportOpaque())
    color(11) print("Exported Opaque Spritesheet successfully")
  else
    fs.write(destination,eapi.leditors[3].SpriteMap.img:data():export())
    color(11) print("Exported Spritesheet successfully")
  end
elseif destination:sub(-4,-1) == ".lua" then --Lua code Exporting.
  fs.write(destination,eapi.leditors[2]:export())
  color(11) print("Exported Luacode successfully")
else --Unknown
  color(8) print("Unknown exporte extension")
end

