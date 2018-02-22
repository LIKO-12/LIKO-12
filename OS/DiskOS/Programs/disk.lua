--PNG Floppy Disk Drive controlling program.
local args = {...} --Get the arguments passed to this program
if #args < 3 or args[1] == "-?" then
  printUsage(
    "disk write <source> <destination> [color]", "Writes a file to a png image",
    "disk read <source> <destination>", "Reads a png image to a file",
    "disk raw-write <source> <destination> [color]", "Writes a file to a png image without a header",
    "disk raw-read <source> <destination>", "Reads a png image to a file"
  )
  return
end

color(8)

local mode = args[1]
if mode ~= "write" and mode ~= "read" then return 1, "Invalid disk task '"..mode.."' !" end

local term = require("terminal")
local source = term.resolve(args[2])
local destination = term.resolve(args[3])
local diskColor = args[4]

local diskheader = "LK12;FileDisk;DiskOS;" --The header of each file disk.

if not fs.exists(source) then return 1, "Source doesn't exist !" end
if fs.exists(destination) then return 1, "Destination already exists !" end
if fs.isDirectory(source) then return 1, "Source can't be a directory !" end

source = fs.read(source)

local FRAM = RamUtils.FRAM

if mode == "read" then
  
  FDD.importDisk(source)
  if memget(FRAM, diskheader:len()) ~= diskheader then
    return 1, "Invalid Header !"
  end
  local fsize = RamUtils.binToNum(memget(FRAM+diskheader:len(),4))
  local fdata = memget(FRAM+diskheader:len()+4, fsize)
  fs.write(destination,fdata)
  color(11) print("Read disk successfully")
  
elseif mode == "write" then
  
  if source:len() > 64*1024-(diskheader:len()+4) then return 1, "File too big (Should be almost 64kb or less) !" end
  memset(FRAM,string.rep(RamUtils.Null,64*1024))
  memset(FRAM,diskheader) --Set the disk header
  memset(FRAM+diskheader:len(), RamUtils.numToBin(source:len(),4)) --Set the file size
  memset(FRAM+diskheader:len()+4,source) --Set the file data
  local data = FDD.exportDisk(diskColor)
  fs.write(destination,data)
  color(11) print("Wrote disk successfully")
  
elseif mode == "raw-read" then
  
  FDD.importDisk(source)
  local fdata = memget(FRAM, 64*1024)
  fs.write(destination,fdata)
  color(11) print("Read disk successfully")
  
elseif mode == "raw-write" then
  
  memset(FRAM,string.rep(RamUtils.Null,64*1024))
  memset(FRAM,source)
  local data = FDD.exportDisk(diskColor)
  fs.write(destination,data)
  color(11) print("Wrote disk successfully")
  
end