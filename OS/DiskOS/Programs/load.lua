local source = select(1,...)

local term = require("C://terminal")
local eapi = require("C://Editors")

if source and source ~= "@clip" then source = term.parsePath(source)..".lk12" elseif source ~= "@clip" then source = eapi.filePath end

print("") --NewLine

if not source then color(8) print("Must provide path to the file to load") return end
if source ~= "@clip" and not fs.exists(source) then color(8) print("File doesn't exists") return end
if source ~= "@clip" and fs.isDirectory(source) then color(8) print("Couldn't load a directory !") return end

local saveData = source == "@clip" and clipboard() or fs.read(source)
if not saveData:sub(0,5) == "LK12;" then color(8) print("This is not a valid LK12 file !!") return end

--LK12;OSData;OSName;DataType;Version;Compression;CompressLevel; data"
--local header = "LK12;OSData;DiskOS;DiskGame;V"..saveVer..";"..sw.."x"..sh..";C:"

local datasum = 0
local nextargiter = saveData:gmatch("(.-);")
local function nextarg()
  local n = nextargiter()
  if n then
    datasum = datasum + n:len() + 1
    return n
  else return n end
end
nextarg() --Skip LK12;

local filetype = nextarg()
if not filetype then color(8) print("Invalid Data !") return end
if filetype ~= "OSData" then
  if filetype == "GPUIMG" then --Import it
    if eapi.leditors[3] then
      eapi.leditors[3]:import(saveData..";0;") --saveData:sub(0,-2))
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

local clevel = nextarg()
if not clevel then color(8) print("Invalid Data !") return end
clevel = string.match(clevel,"CLvl:(.+)")
if not clevel then color(8) print("Invalid Data !") return end clevel = tonumber(clevel)

local data = saveData:sub(datasum+3,-1)

if compress ~= "none" then --Decompress
  data = math.decompress(data,compress,clevel)
end

eapi.filePath = source
eapi:import(data)

color(11) print("Loaded successfully")
