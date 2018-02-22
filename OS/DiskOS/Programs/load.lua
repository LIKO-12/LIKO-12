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
if source ~= "@clip" and not fs.exists(source) then return 1, "File doesn't exists" end
if source ~= "@clip" and fs.isDirectory(source) then return 1, "Couldn't load a directory !" end

local saveData = source == "@clip" and clipboard() or fs.read(source)

if png then
  FDD.importDisk(saveData)
  saveData = memget(RamUtils.FRAM,64*1024)
end

if not saveData:sub(0,5) == "LK12;" then return 1, "This is not a valid LK12 file !!" end

saveData = saveData:gsub("\r\n","\n")

--LK12;OSData;OSName;DataType;Version;Compression;CompressLevel; data"
--local header = "LK12;OSData;DiskOS;DiskGame;V"..saveVer..";"..sw.."x"..sh..";C:"

local datasum = 0
local nextargiter = string.gmatch(saveData,".")
local function nextarg()

  local start = datasum + 1
  
  while true do
    datasum = datasum + 1
    local char = nextargiter()
    
    if not char then
      datasum = datasum - 1
      return
    end
    
    if char == ";" then
      break
    end
  end
  
  return saveData:sub(start,datasum-1)
end
nextarg() --Skip LK12;

local filetype = nextarg()
if not filetype then return 1, "Invalid Data !" end
if filetype ~= "OSData" then
  if filetype == "GPUIMG" then --Import it
    if eapi.leditors[eapi.editors.sprite] then
      local simg = imagedata(screenSize())
      local limg = imagedata(saveData)
      simg:paste(limg)
      eapi.leditors[eapi.editors.sprite]:import(simg:encode()..";0;")
      color(11) print("Imported to sprite editor successfully") return
    end
  elseif filetype == "TILEMAP" then
    if eapi.leditors[eapi.editors.tile] then
      eapi.leditors[eapi.editors.tile]:import(saveData)
      color(11) print("Imported to tilemap editor successfully") return
    end
  else
    return 1, "Can't load '"..filetype.."' files !"
  end
end

local osname = nextarg()
if not osname then return 1, "Invalid Data !" end
if osname ~= "DiskOS" then return 1, "Can't load files from '"..osname.."' OS !" end

local datatype = nextarg()
if not datatype then return 1, "Invalid Data !" end
if datatype ~= "DiskGame" then return 1, "Can't load '"..datatype.."' from '"..osname.."' OS !" end

local dataver = nextarg()
if not dataver then return 1, "Invalid Data !" end
dataver = tonumber(string.match(dataver,"V(%d+)"))
if not dataver then return 1, "Invalid Data !" end
if dataver > _DiskVer then return 1, "Can't load disks newer than V".._DiskVer..", provided: V"..dataver end
if dataver < _MinDiskVer then color(8) return 1, "Can't load disks older than V".._DiskVer..", provided: V"..dataver..", Use 'update_disk' command to update the disk" end

local sw, sh = screenSize()

local datares = nextarg()
if not datares then return 1, "Invalid Data !" end
local dataw, datah = string.match(datares,"(%d+)x(%d+)")
if not (dataw and datah) then return 1, "Invalid Data !" end dataw, datah = tonumber(dataw), tonumber(datah)
if dataw ~= sw or datah ~= sh then return 1, "This disk is made for GPUs with "..dataw.."x"..datah.." resolution, current GPU is "..sw.."x"..sh end

local compress = nextarg()
if not compress then return 1, "Invalid Data !" end
compress = string.match(compress,"C:(.+)")
if not compress then return 1, "Invalid Data !" end

if compress == "binary" then
  
  local revision = nextarg()
  if not revision then return 1, "Invalid Data !" end
  revision = string.match(revision,"Rev:(%d+)")
  if not revision then return 1, "Invalid Data !" end
  
  revision = tonumber(revision)
  
  if revision < 1 then return 1, "Can't load binary saves with revision 0 or lower ("..revision..")" end
  if revision > 1 then return 1, "Can't load binary saves with revision 2 or higher" end
  
  local data = saveData:sub(datasum+1,-1)

  eapi.filePath = source
  eapi:decode(data)
  
else
  
  local clevel = nextarg()
  if not clevel then color(8) print("Invalid Data !") return 1, "Invalid Data !" end
  clevel = string.match(clevel,"CLvl:(.+)")
  if not clevel then color(8) print("Invalid Data !") return 1, "Invalid Data !" end clevel = tonumber(clevel)

  local data = saveData:sub(datasum+2,-1)

  if compress ~= "none" then --Decompress
    local b64data, char = math.b64dec(data)
    if not b64data then cprint(char) cprint(string.byte(char)) error(tostring(char)) end
    data = math.decompress(b64data,compress,clevel)
  end

  eapi.filePath = source
  eapi:import(data)
  
end

color(11) print("Loaded successfully")
