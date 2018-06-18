--Native Builds Utilities.

--Variables.


--Localized Lua Library


--The API
local BuildUtils = {}

--Mount LIKO-12 Sourcecode
function BuildUtils.mountSRC()
  fs.mount(BIOS.getSRC())
end

--Creates a tables tree of files in a directory, with the file content as values, and filenames as keys.
function BuildUtils.filesTree(dir)
  if fs.isFile(dir) then return fs.read(dir) end
  
  local tree = {}
  
  for id, name in ipairs(fs.getDirectoryItems()) do
    tree[id] = BuildUtils.filesTree(dir.."/"..name)
  end
  
  return tree
end

--Get the .lk12 of the game
function BuildUtils.getSavefile()
  local eapi = require("Editors")
  local edata = eapi:export()
  
  return LK12Utils.encodeDiskGame(edata)
end

--Make the buildutils a global
_G["BuildUtils"] = BuildUtils