--A program to load old LIKO-12 cart
local args = {...}
if #args < 1 or args[1] == "-?" then
 printUsage(
  "loadCart filename", "Load old LIKO-12 V0.0.5A Cart"
 )
 return
end

local term = require("terminal")
local eapi = require("Editors")

local function printErr(...)
 local str = table.concat({...})
 color(8) print(str)
end

local source = args[1]
source = term.resolve(source..".lk12")

if not fs.exists(source) then printErr("Cart doesn't exists !") return 1 end
if not fs.isFile(source) then printErr("Cart can't be a directory !") return 1 end

local cartdata = fs.read(source)
local cart = loadstring(cartdata)()

local code = eapi.leditors[eapi.editors["code"]]
local sprite = eapi.leditors[eapi.editors.sprite]

--Loading the code
code:import(cart.code)

--Resizing the image
local cartimg = imagedata(math.b64dec(cart.spritemap))
local newimg = imagedata(screenSize())
newimg:paste(cartimg,0,0)

local sprdata = newimg:encode()..";"..string.char(0)..";"

sprite:import(sprdata)

color(11) print("Loaded old cart successfully")