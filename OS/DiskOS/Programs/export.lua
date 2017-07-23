local destination = select(1,...)

local term = require("terminal")
local eapi = require("Editors")

if not destination then
  printUsage(
    "export <sheet>.png","Exports the spritesheet",
    "export <sheet>.png --opaque","Exports the spritesheet with opaque black",
    "export <luacode>.lua","Exports the game's code"
  )
  return
end

destination = term.resolve(destination)

if fs.exists(destination) and fs.isDirectory(destination) then color(8) print("Destination must not be a directory") return end

if destination:sub(-4,-1) == ".png" then --Sprite Map Exporting.
  if select(2,...) == "-opaque" then
    fs.write(destination,eapi.leditors[eapi.editors.sprite].SpriteMap.img:data():exportOpaque())
    color(11) print("Exported Opaque Spritesheet successfully")
  else
    fs.write(destination,eapi.leditors[eapi.editors.sprite].SpriteMap.img:data():export())
    color(11) print("Exported Spritesheet successfully")
  end
elseif destination:sub(-4,-1) == ".lua" then --Lua code Exporting.
  fs.write(destination,eapi.leditors[eapi.editors.code]:export())
  color(11) print("Exported Luacode successfully")
else --Unknown
  color(8) print("Unknown export extension")
end

