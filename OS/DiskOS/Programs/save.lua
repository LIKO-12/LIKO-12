local destination = select(1,...)
local flag = select(2,...) or ""
local ctype = select(3,...) or "gzip"
local clvl = tonumber(select(4,...) or "9")

local term = require("terminal")
local eapi = require("Editors")

if destination = "-?" then destination = nil end

if destination and destination ~= "@clip" and destination ~= "-?" then
  destination = term.resolve(destination)
  if destination:sub(-5,-1) ~= ".lk12" then destination = destination..".lk12" end
elseif destination ~= "@clip" and destination ~= "-?" then
  destination = eapi.filePath
end

if not destination then
  printUsage(
    "save <file>","Saves the current loaded game",
    "save <file> -c","Saves with compression",
    "save","Saves on the last known file",
    "save @clip","Saves into the clipboard",
    "save <image> --sheet","Saves the spritesheet as external .lk12 image",
    "save <filename> --code","Saves the code as a .lua file"
  )
  return
end

if destination ~= "@clip" and fs.exists(destination) and fs.isDirectory(destination) then color(8) print("Destination must not be a directory") return end

local sw, sh = screenSize()

if string.lower(flag) == "--sheet" then --Sheet export
  local data = eapi.leditors[eapi.editors.sprite]:export(true)
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