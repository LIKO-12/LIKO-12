local destination, flag, ctype, clvl = ...
flag, ctype, clvl = flag or "", ctype or "gzip", tonumber(clvl or "9")

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

if destination ~= "@clip" and string.lower(flag) == "--code" then destination = destination:sub(1,-6)..".lua" end

if destination ~= "@clip" and fs.exists(destination) and fs.isDirectory(destination) then return 1, "Destination must not be a directory" end

if destination ~= "@clip" and fs.isReadonly(destination) then
  return 1, "Destination is readonly !"
end

local backup
if destination ~= "@clip" and fs.exists(destination) and (flag == "" or flag == "-c" or flag == "-b") then
  backup = fs.read(destination)
end

if destination ~= "@clip" and fs.exists(destination) then
  while true do
    color(9) print("Are you sure you want to overwrite the destination file ? (Y/N)") color(6)
    local input = TextUtils.textInput() print("")
    if input then
      input = input:lower()
      if input == "y" or input == "yes" then
        break --The user has accepted to overwrite the file.
      elseif input == "n" or input == "no" then
        return 1, "User declined to overwrite the destination file."
      end
    end
  end
end

local sw, sh = screenSize()

if string.lower(flag) == "--sheet" then --Sheet export
  local data = eapi.leditors[eapi.editors.sprite]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination,data) end
  color(11) print("Exported Spritesheet successfully")
  return
elseif string.lower(flag) == "--map" then --TileMap export
  local data = eapi.leditors[eapi.editors.tile]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination,data) end
  color(11) print("Exported Spritesheet successfully")
  return
elseif string.lower(flag) == "--code" then --Lua code export
  local data = eapi.leditors[eapi.editors.code]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination,data) end
  color(11) print("Exported Lua code successfully")
  return
end

eapi.filePath = destination

local editorsData = (string.lower(flag) == "-b") and eapi:encode() or eapi:export()
local apiVersion = eapi.apiVersion
local diskData = ""

if string.lower(flag) == "-c" or png then
  diskData = LK12Utils.encodeDiskGame(editorsData,flag == "-color" and "gzip" or ctype,clvl,apiVersion)
elseif string.lower(flag) == "-b" then
  diskData = LK12Utils.encodeDiskGame(editorsData,"binary",false,apiVersion)
else
  diskData = LK12Utils.encodeDiskGame(editorsData,false,false,apiVersion)
end

if string.lower(flag) == "-color" and png then
  FDD.newDisk(select(3,...))
else
  FDD.newDisk("Blue")
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

if backup then
  fs.write("C:/_backup.lk12", backup)
end

color(11) print(destination == "@clip" and "Saved to clipboard successfully" or "Saved successfully")