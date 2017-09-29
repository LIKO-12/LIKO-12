local destination = select(1,...)
local flag = select(2,...) or ""
local ctype = select(3,...) or "lz4"
local clvl = tonumber(select(4,...) or "-1")

local term = require("terminal")
local eapi = require("Editors")


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
    "save <image> --sheet","Saves the spritesheet as external .lk12 image"
  )
  return
end

if destination ~= "@clip" and fs.exists(destination) and fs.isDirectory(destination) then color(8) print("Destination must not be a directory") return end

local sw, sh = screenSize()
local data
local msg = {
  color = 11,
  action = "Saved ",
  type = "",
  to = "",
  result = "successfully"
}
flag = string.lower(flag)

if flag == "--sheet" then --Sheet export
  data = eapi.leditors[eapi.editors.sprite]:export(true)
  msg.action = "Exported "
  msg.type = "spritesheet "
elseif flag == "--code" then
  data = eapi.leditors[eapi.editors.code]:export(true)
  if destination ~= "@clip" then destination = destination:sub(0,-6) end
  msg.action = "Exported "
  msg.type = "Lua code "
else
  eapi.filePath = destination
  data = eapi:export()
  --              LK12;OSData;OSName;DataType;Version;Compression;CompressLevel;data"
  local header = "LK12;OSData;DiskOS;DiskGame;V".._DiskVer..";"..sw.."x"..sh..";C:"

  if flag == "-c" then
    data = math.b64enc(math.compress(data, ctype, clvl))
    header = header..ctype..";CLvl:"..tostring(clvl)..";"
    msg.type = "compressed "
  else
    header = header.."none;CLvl:0;"
  end

  data = header.."\n"..data
end

if destination == "@clip" then
  msg.action = "Copied "
  msg.to = "to clipboard "
  clipboard(data)
else
  fs.write(destination,data)
end

color(msg.color)
print(msg.action .. msg.type .. msg.to .. msg.result)