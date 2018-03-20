--Loads third-party libraries.

local Globals = (...) or {}

local function addLibrary(path,name)
  local lib, err = fs.load(path)
  if not lib then error("Failed to load library ("..name.."): "..err) end
  setfenv(lib,Globals) 
  Globals[name] = lib()
end

addLibrary("C:/Libraries/lume.lua","lume")
addLibrary("C:/Libraries/middleclass.lua","class")
addLibrary("C:/Libraries/bump.lua","bump")
addLibrary("C:/Libraries/likocam.lua","likocam")
addLibrary("C:/Libraries/JSON.lua","JSON")
addLibrary("C:/Libraries/luann.lua","luann")
addLibrary("C:/Libraries/genetic.lua","geneticAlgo")

return Globals