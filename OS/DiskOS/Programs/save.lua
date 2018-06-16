local destination = select(1,...)
local flag = select(2,...) or ""
local ctype = select(3,...) or "gzip"
local clvl = tonumber(select(4,...) or "9")

local term = require("terminal")
local eapi = require("Editors")

local png = false

if destination and destination ~= "@clip" and destination ~= "-?" then
  destination = term.resolve(destination)
  if destination:sub(-4,-1) == ".png" then
    png = true
  elseif destination:sub(-5,-1) ~= ".lk12" then
    destination = destination..".lk12"
  end
elseif not destination then
  destination = eapi.filePath
end

if (not destination) or destination == "-?" then
  printUsage(
    "save <file>","Saves the current loaded game",
    "save <file>.png","Save in a png disk",
    "save <file>.png -color [color]","Specify the color of the png disk",
    "save @clip","Saves into the clipboard",
    "save <file> -c","Saves with compression",
    "save <file> -b","Saves in binary format",
    "save","Saves on the last known file",
    "save <image> --sheet","Saves the spritesheet as external .lk12 image",
    "save <filename> --code","Saves the code as a .lua file"
  )
  return
end

if destination ~= "@clip" and fs.exists(destination) and fs.isDirectory(destination) then return 1, "Destination must not be a directory" end

if destination ~= "@clip" and fs.isReadonly(destination) then
  return 1, "Destination is readonly !"
end

local sw, sh = screenSize()

if string.lower(flag) == "--sheet" then --Sheet export
  local data = eapi.leditors[eapi.editors.sprite]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination,data) end
  color(11) print("Exported Spritesheet successfully")
  return
elseif string.lower(flag) == "--map" then --Sheet export
  local data = eapi.leditors[eapi.editors.tile]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination,data) end
  color(11) print("Exported Spritesheet successfully")
  return
elseif string.lower(flag) == "--code" then
  local data = eapi.leditors[eapi.editors.code]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination:sub(1,-6)..".lua",data) end
  color(11) print("Exported Lua code successfully")
  return
end

eapi.filePath = destination

local editorsData = (string.lower(flag) == "-b" or png) and eapi:encode() or eapi:export()
local diskData = ""

if string.lower(flag) == "-c" then
  diskData = LK12Utils.encodeDiskGame(editorsData,ctype,clvl)
elseif string.lower(flag) == "-b" or png then
  diskData = LK12Utils.encodeDiskGame(editorsData,"binary")
else
  diskData = LK12Utils.encodeDiskGame(editorsData)
end

if string.lower(flag) == "-color" and png then
  FDD.newDisk(select(3,...))
end

if destination == "@clip" then
  clipboard(diskData)
elseif png then
  local diskSize = #diskData
  if diskSize > 64*1024 then
    return 1, "Save too big to fit in a floppy disk ("..(math.floor(diskSize/102.4)*10).." kb/ 64 kb) !"
  end
  memset(RamUtils.FRAM, diskData)
  fs.write(destination, FDD.exportDisk())
else
  fs.write(destination,diskData)
end

color(11) print(destination == "@clip" and "Saved to clipboard successfully" or "Saved successfully")