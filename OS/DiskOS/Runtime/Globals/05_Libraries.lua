--Loads external libraries.

local Globals = (...) or {}

local Libraries = {}

local function addLibrary(path,name)
  local lib, err = fs.load(path)
  if not lib then error("Failed to load library ("..name.."): "..err) end
  setfenv(lib,Globals)
  Libraries[name] = lib
end

addLibrary(_SystemDrive..":/Libraries/lume.lua","lume")
addLibrary(_SystemDrive..":/Libraries/middleclass.lua","class")
addLibrary(_SystemDrive..":/Libraries/bump.lua","bump")
addLibrary(_SystemDrive..":/Libraries/likocam.lua","likocam")
addLibrary(_SystemDrive..":/Libraries/JSON.lua","JSON")
addLibrary(_SystemDrive..":/Libraries/luann.lua","luann")
addLibrary(_SystemDrive..":/Libraries/genetic.lua","geneticAlgo")
addLibrary(_SystemDrive..":/Libraries/vector.lua","vector")
addLibrary(_SystemDrive..":/Libraries/spritesheet.lua","spritesheet")

function Globals.Library(name)
  if type(name) ~= "string" then return error("Library name should be a string, got: "..type(name)) end
  if not Libraries[name] then return error("Library '"..name.."' doesn't exists !") end
  return Libraries[name]()
end

return Globals