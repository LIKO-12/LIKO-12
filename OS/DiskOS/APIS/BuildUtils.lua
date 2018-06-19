--Native Builds Utilities.

local likoZIP = require("Libraries.liko-zip")

--Variables.


--Localized Lua Library


--The API
local BuildUtils = {}

--Mount LIKO-12 Sourcecode
function BuildUtils.mountSRC()
  return fs.mountZIP(BIOS.getSRC())
end

--Creates a tables tree of files in a directory, with the file content as values, and filenames as keys.
function BuildUtils.filesTree(dir)
  if fs.isFile(dir) then return fs.read(dir) end
  
  local tree = {}
  
  for id, name in ipairs(fs.getDirectoryItems(dir)) do
    tree[name] = BuildUtils.filesTree(dir.."/"..name)
  end
  
  return tree
end

--Create a .zip of a files tree
function BuildUtils.packZIP(tree)
  local writer = likoZIP.newZipWriter()
  
  local function index(dir,path)
    for fileName, fileData in pairs(dir) do
      fileName = path and path.."/"..fileName or fileName
      
      if type(fileData) == "string" then
        writer.addFile(fileName,fileData,0)
      else --Sub directory
        index(fileData,fileName,true)
      end
    end
  end
  
  index(tree)
  
  return writer.finishZip():read()
end

--Get the .lk12 of the game
function BuildUtils.getSavefile()
  local eapi = require("Editors")
  local edata = eapi:export()
  
  return LK12Utils.encodeDiskGame(edata)
end

--Make the buildutils a global
_G["BuildUtils"] = BuildUtils