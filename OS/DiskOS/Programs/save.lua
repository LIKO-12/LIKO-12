local destination = select(1,...)
local flag = select(2,...) or ""
local ctype = select(3,...) or "lz4"
local clvl = tonumber(select(4,...) or "-1")

local term = require("C://terminal")
local eapi = require("C://Editors")
destination = term.parsePath(destination)..".lk12"

if fs.exists(destination) and fs.isDirectory(destination) then color(9) print("Destination must not be a directory") return end

local sw, sh = screenSize()

local data = eapi:export()
--              LK12;OSData;OSName;DataType;Version;Compression;CompressLevel;data"
local header = "LK12;OSData;DiskOS;DiskGame;V".._DiskVer..";"..sw.."x"..sh..";C:"

if string.lower(flag) == "-c" then
  data = math.compress(data, ctype, clvl)
  header = header..ctype..";CLvl:"..tostring(clvl)..";"
else
  header = header.."none;CLvl:0;"
end

fs.write(destination,header..data)

color(12) print("\nSaved successfully")