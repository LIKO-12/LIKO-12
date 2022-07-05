local destination = ...

local term = require("terminal")
local eapi = require("Editors")

if (not destination) or destination == "-?" then
  printUsage(
    "export <sheet>.png","Exports the spritesheet",
    "export <sheet>.png --opaque","Exports the spritesheet with opaque black",
    "export @label","Exports the spritesheet to the label image",
    "export <luacode>.lua","Exports the game's code"
  )
  return
end

if destination ~= "@label" then
  destination = term.resolve(destination)

  if fs.exists(destination) and fs.isDirectory(destination) then return 1, "Destination must not be a directory" end
  if fs.isReadonly(destination) then return 1, "Destination is readonly !" end
end

if destination == "@label" then
  
  local sprimg = eapi.leditors[eapi.editors.sprite].SpriteMap.img:data()
  getLabelImage():paste(sprimg)
  
  color(11) print("Exported label image successfully")
  
elseif destination:sub(-4,-1) == ".png" then --Sprite Map Exporting.
  if select(2,...) == "--opaque" then
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
  return 1, "Unknown export extension"
end

