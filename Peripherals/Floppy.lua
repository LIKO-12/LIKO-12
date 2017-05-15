local bit = require("bit")
local band = bit.band

return function(config)
  local devkit = {}
  
  function devkit.loadImage(pngdata)
    local ok,err = pcall(love.filesystem.newFileData,pngdata,"floppy.png")
    if not ok then return false, err end
    local ok,err = pcall(love.image.newImageData,err)
    if not ok then return false, err end
    return true, err
  end
  
  local fapi = {}
  
  --Apply the label image into the floppy disk.
  function fapi.setLabelImage(floppypng,labelpng,x,y)
    
  end
  
  --Write data to the floppy disk.
  function fapi.burnData(floppypng,data)
    
  end
  
  --Clear the data from the floppydisk and make it ready for use.
  function fapi.format(floppypng)
    local ok, id = devkit.loadImage(floppypng)
    if not ok then return false, "Invalid PNG Data." end
    local filter = tonumber(11111100 ,2)
    id:mapPixel(function(x,y, r,g,b,a)
      return band(r,filter), band(g,filter), band(b,filter), band(a,filter)
    end)
    return true, id:encode("png"):getString()
  end
  
  --Read the saved data on the floppy image.
  function fapi.readData(floppypng)
    local ok,id = devkit.loadImage(floppypng)
    if not ok then return false, "Invalid PNG Data." end
    
  end
  
  return fapi
end