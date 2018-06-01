--Native Builds Utilities.

--Variables.


--Localized Lua Library


--The API
local BuildUtils = {}

--Mount LIKO-12 Sourcecode
function BuildUtils.mountSRC()
  fs.mount(BIOS.getSRC())
end

function BuildUtils.filesTree(dir)
  if fs.isFile(dir) then return fs.read(dir) end
  
  local tree = {}
  
  for id, name in ipairs(fs.getDirectoryItems()) do
    tree[id] = BuildUtils.filesTree(dir.."/"..name)
  end
  
  return tree
end

function BuildUtils.getSavefile()
  
end

--Make the buildutils a global
_G["BuildUtils"] = BuildUtils