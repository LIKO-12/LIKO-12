--PNG Floppy Disk Drive controlling program.
local args = {...} --Get the arguments passed to this program
if #args < 3 or args[1] == "-?" then
  printUsage(
    "disk write <source> <destination>", "Writes a file to a png image",
    "disk read <source> <destination>", "Reads a png image to a file"
  )
  return
end

color(8)

local mode = args[1]
if mode ~= "write" and mode ~= "read" then print("Invalid disk task '"..mode.."' !") end

local term = require("terminal")
local source = term.resolve(args[2])
local destination = term.resolve(args[3])

if not fs.exists(source) then print("Source doesn't exist !") return end
if fs.exists(destination) then print("Destination already exists !") return end
if fs.isDirectory(source) then print("Source can't be a directory !") return end

source = fs.read(source)

if mode == "read" then
  FDD.importDisk(source)
  local fdata = {}
  for i=0,64*1024-1 do table.insert(fdata,string.char(peek(RamUtils.FRAM+i))) end
  fdata = table.concat(fdata)
  fs.write(destination,fdata)
  color(11) print("Read disk successfully")
elseif mode == "write" then
  if source:len() > 64*1024 then print("File too big (Should be 64kb or less) !") return end
  memset(0x6000,string.rep("\n",64*1024))
  memset(0x6000,source)
  local data = FDD.exportDisk()
  fs.write(destination,data)
  color(11) print("Wrote disk successfully")
end