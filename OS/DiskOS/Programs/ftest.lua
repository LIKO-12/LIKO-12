--Floppy peripheral test
local fimg = select(1,...)
local dest = select(2,...)
local mode = select(3,...)
local source = select(4,...)

local term = require("C://terminal")

fimg, dest, source = term.parsePath(fimg), term.parsePath(dest),  source and term.parsePath(source) or ""

local fimg = fs.read(fimg)
if mode == "read" then
  local data = Floppy.readData(fimg)
  fs.write(dest,data)
elseif mode == "write" then
  fimg = Floppy.format(fimg)
  local data = fs.read(source)
  fimg = Floppy.burnData(fimg,data)
  fs.write(dest,fimg)
end

print(" Done")