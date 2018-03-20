--Games runtime API

local rt = {}

function rt.loadResources()
  local scripts = fs.getDirectoryItems("C:/Runtime/Resources/")
  
  for id, name in ipairs(scripts) do
    scripts[id] = fs.load("C:/Runtime/Resources/"..name)
  end
  
  return scripts
end

function rt.loadGlobals()
  local scripts = fs.getDirectoryItems("C:/Runtime/Globals/")
  
  for id, name in ipairs(scripts) do
    scripts[id] = fs.load("C:/Runtime/Globals/"..name)
  end
  
  return scripts
end

function rt.newGlobals()
  
  local glob = _FreshGlobals()
glob._G = glob --Magic ;)
  
end

return rt