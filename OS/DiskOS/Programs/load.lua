local source = select(1,...)

local term = require("terminal")
local eapi = require("Editors")

if source and source ~= "@clip" and source ~= "-?" then
  source = term.resolve(source)
  if source:sub(-5,-1) ~= ".lk12" then source = source..".lk12" end
elseif source ~= "@clip" and source ~= "-?" then source = eapi.filePath end

if not source or source == "-?" then
  printUsage(
    "load <file>","Loads a game into memory",
    "load","Reloads the current game",
    "load @clip","Load from clipboard"
  )
  return
end
if source ~= "@clip" and not fs.exists(source) then color(8) print("File doesn't exists") return end
if source ~= "@clip" and fs.isDirectory(source) then color(8) print("Couldn't load a directory !") return end

local saveData = source == "@clip" and clipboard() or fs.read(source)
if not saveData:sub(0,5) == "LK12;" then color(8) print("This is not a valid LK12 file !!") return end

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
if not filetype then color(8) print("Invalid Data !") return end
if filetype ~= "OSData" then
  if filetype == "GPUIMG" then --Import it
    if eapi.leditors[eapi.editors.sprite] then
      local simg = imagedata(screenSize())
      local limg = imagedata(saveData)
      simg:paste(limg)
      eapi.leditors[eapi.editors.sprite]:import(simg:encode()..";0;")
      color(11) print("Imported to sprite editor successfully") return
    end
  else
    color(8) print("Can't load '"..filetype.."' files !") return
  end
end

local osname = nextarg()
if not osname then color(8) print("Invalid Data !") return end
if osname ~= "DiskOS" then color(8) print("Can't load files from '"..osname.."' OS !") return end

local datatype = nextarg()
if not datatype then color(8) print("Invalid Data !") return end
if datatype ~= "DiskGame" then color(8) print("Can't load '"..datatype.."' from '"..osname.."' OS !") return end

local dataver = nextarg()
if not dataver then color(8) print("Invalid Data !") return end
dataver = tonumber(string.match(dataver,"V(%d+)"))
if not dataver then color(8) print("Invalid Data !") return end
if dataver > _DiskVer then color(8) print("Can't load disks newer than V".._DiskVer..", provided: V"..dataver) return end
if dataver < _DiskVer then color(8) print("Can't load disks older than V".._DiskVer..", provided: V"..dataver..", Use 'update_disk' command to update the disk") return end

local sw, sh = screenSize()

local datares = nextarg()
if not datares then color(8) print("Invalid Data !") return end
local dataw, datah = string.match(datares,"(%d+)x(%d+)")
if not (dataw and datah) then color(8) print("Invalid Data !") return end dataw, datah = tonumber(dataw), tonumber(datah)
if dataw ~= sw or datah ~= sh then color(8) print("This disk is made for GPUs with "..dataw.."x"..datah.." resolution, current GPU is "..sw.."x"..sh) return end

local compress = nextarg()
if not compress then color(8) print("Invalid Data !") return end
compress = string.match(compress,"C:(.+)")
if not compress then color(8) print("Invalid Data !") return end

if compress == "binary" then
  
  local revision = nextarg()
  if not revision then color(8) print("Invalid Data !") return end
  revision = string.match(revision,"Rev:(%d+)")
  if not revision then color(8) print("Invalid Data !") return end
  
  revision = tonumber(revision)
  
  if revision < 1 then color(8) print("Can't load binary saves with revision 0 or lower ("..revision..")") end
  if revision > 1 then color(8) print("Can't load binary saves with revision 2 or higher") end
  
  local data = saveData:sub(datasum+2,-1)

  eapi.filePath = source
  eapi:decode(data)
  
else
  
  local clevel = nextarg()
  if not clevel then color(8) print("Invalid Data !") return end
  clevel = string.match(clevel,"CLvl:(.+)")
  if not clevel then color(8) print("Invalid Data !") return end clevel = tonumber(clevel)

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
