--Load a .lk12 sheet, compress it, b64 encode it, and set it to clipboard.

local source = table.concat({...})

if source == "-?" or source == "" then
  printUsage("SheetToClip <sheet file>", "Load a sprite sheet, compresses it, b64 encode it and set it to clipboard")
  return
end

local term = require("terminal")

source = term.resolve(source..".lk12")

if not fs.exists(source) then return 1, "Sheet doesn't exist !" end
if not fs.isFile(source) then return 1, "Sheet can't be a folder !" end

color(12)

print("Reading sheet data...") flip()

local data = fs.read(source)

print("Loading sheet data...") flip()

local img = imagedata(data)

print("Generating sheet string...") flip()

local str = img:encode()

print("Compressing sheet string...") flip()

local cstr = math.compress(str,"gzip",9)

print("Base64 Encoding data...") flip()

local bstr = math.b64enc(cstr)

print("Generating code...") flip()

local code = {
  'local Sheet = SpriteSheet(image(math.decompress(math.b64dec("',
  bstr,
  '"),"gzip",9)),24,16)'
}

code = table.concat(code)

clipboard(code)

color(11)

print("The code has been set to your clipboard")