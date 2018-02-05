local perpath = select(1,...) --The path to the FDD folder

local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

return function(config)
  
  local GPUKit = config.GPUKit or error("The FDD peripheral requires the GPUKit")
  local RAM = config.RAM or error("The FDD peripheral requires the RAM peripheral")
  
  local FIMG --The floppy disk image
  local DiskSize = config.DiskSize or 64*1024 --The floppy disk size
  local FRAMAddress = config.FRAMAddress or 0 --The floppy ram start address
  
  --The color palette
  local ColorSet = {}
  
  for i=0,15 do
    local r,g,b,a = unpack(GPUKit._ColorSet[i])
    r,g,b,a = band(r,252), band(g,252), band(b,252), 252
    ColorSet[i] = {r,g,b,a}
    ColorSet[r*10^9 + g*10^6 + b*10^3 + a] = i
  end
  
  --The label image
  local LabelImage = GPUKit.LabelImage
  local LabelX, LabelY, LabelW, LabelH = 32,120, GPUKit._LIKO_W, GPUKit._LIKO_H
  
  --DiskCleanupMapper
  local function _CleanUpDisk(x,y,r,g,b,a)
    return band(r,252), band(g,252), band(b,252), band(a,252)
  end
  
  --DiskWriteMapper
  local WritePos = 0
  local function _WriteDisk(x,y,r,g,b,a)
    local byte = RAM.peek(FRAMAddress+WritePos)
    r = bor(r, band( rshift(byte ,6), 3) )
    g = bor(g, band( rshift(byte ,4), 3) )
    b = bor(b, band( rshift(byte ,2), 3) )
    a = bor(a, band(byte,3))
    WritePos = (WritePos + 1) % (DiskSize)
    return r, g, b, a
  end
  
  --DiskReadMapper
  local ReadPos = 0
  local function _ReadDisk(x,y,r,g,b,a)
    local r2 = lshift( band(r, 3), 6)
    local g2 = lshift( band(g, 3), 4)
    local b2 = lshift( band(b, 3), 2)
    local a2 = band(a, 3)
    local byte = bor(r2,g2,b2,a2)
    RAM.poke(FRAMAddress+ReadPos,byte)
    ReadPos = (ReadPos + 1) % (DiskSize)
    return r, g, b, a
  end
  
  --LabelDrawMapper
  local function _DrawLabel(x,y,r,g,b,a)
    FIMG:setPixel(LabelX+x,LabelY+y,unpack(ColorSet[r]))
    return r,g,b,a
  end
  
  --LabelScanMapper
  local function _ScanLabel(x,y,r,g,b,a)
    local r,g,b,a = band(r,252), band(g,252), band(b,252), band(a,252)
    local code = r*10^9 + g*10^6 + b*10^3 + a
    local id = ColorSet[code] or 0
    LabelImage:setPixel(x,y,id,0,0,255)
  end
  
  --The API starts here--
  local fapi, yfapi = {}, {}
  
  --Create a new floppy disk and mount it
  --tname -> template name, without the .png extension
  function fapi.newDisk(tname)
    local tname = tname or "Blue"
    if type(tname) ~= "string" then return error("Disk template name must be a string or a nil, provided: "..type(tname)) end
    if not love.filesystem.exists(perpath..tname..".png") then return error("Disk template '"..tname.."' doesn't exist !") end
    
    FIMG = love.image.newImageData(perpath..tname..".png")
  end
  
  function fapi.exportDisk()
    --Clean up any already existing data on the disk.
    FIMG:mapPixel(_CleanUpDisk)
    
    --Write the label image
    LabelImage:mapPixel(_DrawLabel)
    
    --Write new data
    FIMG:mapPixel(_WriteDisk)
    
    return FIMG:encode("png"):getString()
  end
  
  function fapi.importDisk(data)
    if type(data) ~= "string" then return error("Data must be a string, provided: "..type(data)) end
    
    FIMG = love.image.newImageData(love.filesystem.newFileData(data,"image.png"))
    
    --Scan the label image
    for y=LabelY,LabelY+LabelH-1 do
      for x=LabelX,LabelX+LabelW-1 do
        _ScanLabel(x-LabelX,y-LabelY,FIMG:getPixel(x,y))
      end
    end
    
    --Read the data
    FIMG:mapPixel(_ReadDisk)
  end
  
  --Initialize with the default disk
  fapi.newDisk()
  
  return fapi
end