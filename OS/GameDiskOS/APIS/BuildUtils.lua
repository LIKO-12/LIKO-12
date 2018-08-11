--Native Builds Utilities.

local likoZIP = require("Libraries.liko-zip")
local likoPE = require("Libraries.liko-pe")

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

function BuildUtils.encodeIco(icons,transparentColor)
  local ico = "\0\0\1\0"..string.char(#icons).."\0"
  
  local entriesSize = 16*#icons
  local dataPos = #ico + entriesSize
  
  local icoEntries = {}
  local icoData = {}
  
  for i=1, #icons do
    icoEntries[#icoEntries+1] = string.char(icons[i]:width()%256)
    icoEntries[#icoEntries+1] = string.char(icons[i]:height()%256)
    icoEntries[#icoEntries+1] = "\0\0\0\0\0\0"
    
    local pngData
    if transparentColor then
      palt(0,false) palt(transparentColor,true)
      pngData = icons[i]:export()
      palt()
    else
      pngData = icons[i]:exportOpaque()
    end
    
    icoEntries[#icoEntries+1] = BinUtils.numToBin(#pngData,4)
    icoEntries[#icoEntries+1] = BinUtils.numToBin(dataPos,4)
    icoData[#icoData+1] = pngData
    
    dataPos = dataPos + #pngData
  end
  
  return ico .. table.concat(icoEntries) .. table.concat(icoData)
end

function BuildUtils.patchExeIco(exe,ico)
  local ok, newexe = likoPE.patchIcon(exe,ico)
  return ok and newexe or exe
end

--Make the buildutils a global
_G["BuildUtils"] = BuildUtils