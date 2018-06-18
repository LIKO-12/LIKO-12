--Loads third-party libraries.

local Globals = (...) or {}

local function addLibrary(path,name)
  local lib, err = fs.load(path)
  if not lib then error("Failed to load library ("..name.."): "..err) end
  setfenv(lib,Globals) 
  Globals[name] = lib()
end

addLibrary("Libraries/lume.lua","lume")
addLibrary("Libraries/middleclass.lua","class")
addLibrary("Libraries/bump.lua","bump")
addLibrary("Libraries/likocam.lua","likocam")
addLibrary("Libraries/JSON.lua","JSON")
addLibrary("Libraries/luann.lua","luann")
addLibrary("Libraries/genetic.lua","geneticAlgo")

return Globals