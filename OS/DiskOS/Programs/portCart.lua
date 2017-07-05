--This file is used to part old 0.0.5 liko12 carts into the new disks
--The code of the game itself must be ported manually
--But this will help in loading the cart
--Note that this ports carts to disks for 192x128 resolution
local disk = "return {\n['luacode'] = "

local term = require("C://terminal")
local eapi = require("C://Editors")

local source = select(1,...)

if not source or source == "-?" then
  printUsage(
    "portCart <cart>","Ports old LIKO-12 cartridges from V0.0.5A"
  )
  return
end

if source then source = term.resolve(source)..".lk12" end

if not source then color(8) print("Must provide path to the file to port") return end
if not fs.exists(source) then color(8) print("File doesn't exists") return end
if fs.isDirectory(source) then color(8) print("Couldn't port a directory !") return end

local cartData = fs.read(source)
cartData = loadstring(cartData)()

disk = disk..string.format("%q",cartData.code)..",\n['spritesheet'] = "
local oldimage = imagedata(math.b64dec(cartData.spritemap))
local image = imagedata(192,128)
image:paste(oldimage)
image = image:encode()

disk = disk..string.format("%q",image).."\n}"

eapi:import(disk)
