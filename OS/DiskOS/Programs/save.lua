local destination = select(1,...)
local flag = select(2,...) or ""
local ctype = select(3,...) or "lz4"
local clvl = tonumber(select(4,...) or "-1")

local term = require("C://terminal")
local eapi = require("C://Editors")


if destination and destination ~= "@clip" and destination ~= "-?" then destination = term.resolve(destination)..".lk12" elseif destination ~= "@clip" and destination ~= "-?" then
  destination = eapi.filePath
end

if not destination or then
  printUsage(
    "save <file>","Saves the current loaded game",
    "save <file> -c","Saves with compression",
    "save","Saves on the last known file",
    "save @clip","Saves into the clipboard",
    "save <image> --sheet","Saves the spritesheet as external .lk12 image"
  )
  return
end

if destination ~= "@clip" and fs.exists(destination) and fs.isDirectory(destination) then color(8) print("Destination must not be a directory") return end

local sw, sh = screenSize()

if string.lower(flag) == "--sheet" then --Sheet export
  local data = eapi.leditors[3]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination,data) end
  color(11) print("Exported Spritesheet successfully")
  return
elseif string.lower(flag) == "--code" then
  local data = eapi.leditors[2]:export(true)
  if destination == "@clip" then clipboard(data) else fs.write(destination:sub(0,-6),data) end
  color(11) print("Exported Lua code successfully")
  return
end

eapi.filePath = destination
local data = eapi:export()
--              LK12;OSData;OSName;DataType;Version;Compression;CompressLevel;data"
local header = "LK12;OSData;DiskOS;DiskGame;V".._DiskVer..";"..sw.."x"..sh..";C:"

if string.lower(flag) == "-c" then
  data = math.b64enc(math.compress(data, ctype, clvl))
  header = header..ctype..";CLvl:"..tostring(clvl)..";"
else
  header = header.."none;CLvl:0;"
end

if destination == "@clip" then
  clipboard(header.."\n"..data)
else
  fs.write(destination,header.."\n"..data)
end

color(11) print(destination == "@clip" and "Saved to clipboard successfully" or "Saved successfully")