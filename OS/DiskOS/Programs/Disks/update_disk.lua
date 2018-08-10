local source = select(1,...)

if not source or source == "-?" then
  printUsage(
    "update_disk <disk>","Updates an outdated LIKO-12 disk"
  )
  return
end


local term = require("terminal")
local eapi = require("Editors")

if source then source = term.resolve(source)..".lk12" else source = eapi.filePath end
if not fs.exists(source) then return 1, "File doesn't exists" end
if fs.isDirectory(source) then return 1, "Couldn't load a directory !" end

local saveData = fs.read(source)..";"
if not saveData:sub(0,5) == "LK12;" then return 1, "This is not a valid LK12 file !!" end

--LK12;OSData;OSName;DataType;Version;Compression;CompressLevel; data"
--local header = "LK12;OSData;DiskOS;DiskGame;V"..saveVer..";"..sw.."x"..sh..";C:"

local nextarg = saveData:gmatch("(.-);")
nextarg() --Skip LK12;

local filetype = nextarg()
if not filetype then return 1, "Invalid Data !" end
if filetype ~= "OSData" then
  return 1, "Can't update '"..filetype.."' files !"
end

local osname = nextarg()
if not osname then return 1, "Invalid Data !" end
if osname ~= "DiskOS" then return 1, "Can't update files from '"..osname.."' OS !" end

local datatype = nextarg()
if not datatype then return 1, "Invalid Data !" end
if datatype ~= "DiskGame" then return 1, "Can't update '"..datatype.."' from '"..osname.."' OS !" end

local dataver = nextarg()
if not dataver then return 1, "Invalid Data !" end
dataver = tonumber(string.match(dataver,"V(%d+)"))
if not dataver then return 1, "Invalid Data !" end
if dataver == LK12Utils.DiskVer then color(8) print("Disk is already up to date !") return 0 end
if dataver > 1 then return 1, "Can't update disks newer than V1, provided: V"..dataver end
if dataver < 1 then return 1, "Can't update disks older than V1, provided: V"..dataver end

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

local clevel = nextarg()
if not clevel then return 1, "Invalid Data !" end
clevel = string.match(clevel,"CLvl:(.+)")
if not clevel then return 1, "Invalid Data !" end clevel = tonumber(clevel)

--local data = saveData:sub(datasum+1,-1)
local data = ""
for d in nextarg do data = data..d..";" end

if compress ~= "none" then --Decompress
  data = math.decompress(data,compress,clevel)
end

eapi.filePath = source
eapi:clearData()

if dataver == 1 then
  local chunk = loadstring(data)
  setfenv(chunk,{})
  data = chunk()
  for k, id in ipairs(eapi.saveid) do
    if id ~= -1 and data[tostring(id)] and eapi.leditors[k].import then
      if id == "spritesheet" then
        local d = data[id]:gsub("\n","")
        local w,h,imgdata = string.match(d,"LK12;GPUIMG;(%d+)x(%d+);(.+)")
        imgdata = imgdata:sub(0,w*h)
        imgdata = "LK12;GPUIMG;"..w.."x"..h..";"..imgdata..";0;"
        eapi.leditors[k]:import(imgdata)
      else
        if id == "luacode" then data[id] = data[id]:sub(2,-1) end
        eapi.leditors[k]:import(data[tostring(id)])
      end
    end
  end
end

term.execute("save")

color(11) print("Updated to Disk V"..LK12Utils.DiskVer.." Successfully")
