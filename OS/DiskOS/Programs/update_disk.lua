local source = select(1,...)

local term = require("C://terminal")
local eapi = require("C://Editors")

if source then source = term.resolve(source)..".lk12" else source = eapi.filePath end

if not source then color(8) print("Must provide path to the file to update") return end
if not fs.exists(source) then color(8) print("File doesn't exists") return end
if fs.isDirectory(source) then color(8) print("Couldn't load a directory !") return end

local saveData = fs.read(source)..";"
if not saveData:sub(0,5) == "LK12;" then color(8) print("This is not a valid LK12 file !!") return end

--LK12;OSData;OSName;DataType;Version;Compression;CompressLevel; data"
--local header = "LK12;OSData;DiskOS;DiskGame;V"..saveVer..";"..sw.."x"..sh..";C:"

local nextarg = saveData:gmatch("(.-);")
nextarg() --Skip LK12;

local filetype = nextarg()
if not filetype then color(8) print("Invalid Data !") return end
if filetype ~= "OSData" then
  color(8) print("Can't update '"..filetype.."' files !") return
end

local osname = nextarg()
if not osname then color(8) print("Invalid Data !") return end
if osname ~= "DiskOS" then color(8) print("Can't update files from '"..osname.."' OS !") return end

local datatype = nextarg()
if not datatype then color(8) print("Invalid Data !") return end
if datatype ~= "DiskGame" then color(8) print("Can't update '"..datatype.."' from '"..osname.."' OS !") return end

local dataver = nextarg()
if not dataver then color(8) print("Invalid Data !") return end
dataver = tonumber(string.match(dataver,"V(%d+)"))
if not dataver then color(8) print("Invalid Data !") return end
if dataver == _DiskVer then color(8) print("Disk is already up to date !") return end
if dataver > 1 then color(8) print("Can't update disks newer than V1, provided: V"..dataver) return end
if dataver < 1 then color(8) print("Can't update disks older than V1, provided: V"..dataver) return end

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

--local data = saveData:sub(datasum+1,-1)
local data = ""
for d in nextarg do data = data..d..";" end
fs.write("C://tdata",data)

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

color(11) print("Updated to Disk V".._DiskVer.." Successfully")
