local source = select(1,...)

local term = require("terminal")
local eapi = require("Editors")

local png = false

if source and source ~= "@clip" and source ~= "-?" then
  source = term.resolve(source)
  if source:sub(-4,-1) == ".png" then
    png = true
  elseif source:sub(-5,-1) ~= ".lk12" then
    local lksrc = source..".lk12"
    if fs.exists(lksrc) then
      source = lksrc
    elseif fs.exists(source..".png") then
      source = source..".png"
      png = true
    else
      source = lksrc
    end
  end
elseif source ~= "@clip" and source ~= "-?" then source = eapi.filePath end

if not source or source == "-?" then
  printUsage(
    "load <file>","Loads a game into memory",
    "load","Reloads the current game",
    "load @clip","Load from clipboard"
  )
  return
end
if source ~= "@clip" and not fs.exists(source) then return 1, "File doesn't exist" end
if source ~= "@clip" and fs.isDirectory(source) then return 1, "Couldn't load a directory !" end

local lk12Data = source == "@clip" and clipboard() or fs.read(source)

if png then
  FDD.importDisk(lk12Data)
  lk12Data = memget(RamUtils.FRAM,64*1024)
end

local lk12Type, errMsg = LK12Utils.identifyType(lk12Data)
if not lk12Type then return 1, errMsg or "Unkown Error" end

if lk12Type ~= "OSData" then
  if lk12Type == "GPUIMG" then --Import it
    if eapi.leditors[eapi.editors.sprite] then
      local simg = imagedata(screenSize())
      local limg = imagedata(lk12Data)
      simg:paste(limg)
      eapi.leditors[eapi.editors.sprite]:import(simg:encode()..";0;")
      color(11) print("Imported to sprite editor successfully") return
    end
  elseif lk12Type == "TILEMAP" then
    if eapi.leditors[eapi.editors.tile] then
      eapi.leditors[eapi.editors.tile]:import(lk12Data)
      color(11) print("Imported to tilemap editor successfully") return
    end
  else
    return 1, "Can't load '"..lk12Type.."' files !"
  end
end

local eData, binary, apiVer = LK12Utils.decodeDiskGame(lk12Data)
if not eData then return 1, binary or "Unkown Error" end

if binary then
  eapi:decode(eData)
else
  eapi:import(eData)
end

eapi.filePath = source
eapi.apiVersion = apiVer

if apiVer < _APIVer then
  color(9) print("Applied compatiblity layer for API v"..apiVer)
  color(6) print("Newer APIs are not available")
  color(9) print("Use ",false) color(10) print("setapi",false) color(9) print(" command to upgrade to API v".._APIVer.."\n")
end

color(11) print("Loaded successfully")
