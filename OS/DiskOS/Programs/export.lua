local destination = select(1,...)

local term = require("C://terminal")
local eapi = require("C://Editors")

if not destination then color(9) print("\nMust provide the destination file path") return end

destination = term.parsePath(destination)

if fs.exists(destination) and fs.isDirectory(destination) then color(9) print("Destination must not be a directory") return end

if destination:sub(-4,-1) == ".png" then --Sprite Map Exporting.
  if select(2,...) == "-opaque" then
    fs.write(destination,eapi.leditors[3].SpriteMap.img:data():exportOpaque())
    color(12) print("\nExported Opaque Spritesheet successfully")
  else
    fs.write(destination,eapi.leditors[3].SpriteMap.img:data():export())
    color(12) print("\nExported Spritesheet successfully")
  end
elseif destination:sub(-4,-1) == ".lua" then --Lua code Exporting.
  fs.write(destination,eapi.leditors[2]:export())
  color(12) print("\nExported Luacode successfully")
else --Unknown
  color(9) print("\nUnknown exporte extension")
end

