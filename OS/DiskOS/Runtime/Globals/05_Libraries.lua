--Loads external libraries.

local term = require("terminal")
local MainDrive = term.getMainDrive()

local Globals = (...) or {}

local Libraries = {}

local function addLibrary(path,name)
  local lib, err = fs.load(path)
  if not lib then error("Failed to load library ("..name.."): "..err) end
  setfenv(lib,Globals)
  Libraries[name] = lib
end

addLibrary(MainDrive..":/Libraries/lume.lua","lume")
addLibrary(MainDrive..":/Libraries/middleclass.lua","class")
addLibrary(MainDrive..":/Libraries/bump.lua","bump")
addLibrary(MainDrive..":/Libraries/likocam.lua","likocam")
addLibrary(MainDrive..":/Libraries/JSON.lua","JSON")
addLibrary(MainDrive..":/Libraries/luann.lua","luann")
addLibrary(MainDrive..":/Libraries/genetic.lua","geneticAlgo")
addLibrary(MainDrive..":/Libraries/vector.lua","vector")
addLibrary(MainDrive..":/Libraries/spritesheet.lua","spritesheet")

function Globals.Library(name)
  if type(name) ~= "string" then return error("Library name should be a string, got: "..type(name)) end
  if not Libraries[name] then return error("Library '"..name.."' doesn't exists !") end
  return Libraries[name]()
end

return Globals