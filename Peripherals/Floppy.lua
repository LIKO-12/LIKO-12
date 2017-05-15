local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

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
    if type(floppypng) ~= "string" then return false, "Floppy PNG Data must be a string, provided: "..type(floppypng) end
    if type(labelpng) ~= "string" then return false, "Label PNG Data must be a string, provided: "..type(labelpng) end
    if type(x) ~= "number" then return false, "Label PNG Data must be a string, provided: "..type(labelpng) end
    
    return true
  end
  
  --Write data to the floppy disk.
  function fapi.burnData(floppypng,data)
    if type(floppypng) ~= "string" then return false, "Floppy PNG Data must be a string, provided: "..type(floppypng) end
    if type(data) ~= "string" then return false, "Data must be a string, provided: "..type(data) end
    local ok,id = devkit.loadImage(floppypng)
    if not ok then return false, "Invalid PNG Data." end
    local dlen = data:len()
    data = tostring(dlen)..";"..data
    local rf, gf, bf, af = tonumber(11 ,2), tonumber(1100 ,2), tonumber(110000 ,2), tonumber(11000000 ,2)
    local dend = dlen+tostring(dlen):len()+1
    
    local cpos = 1
    local function nextchar()
      if cpos > dend then return "\0" else
        cpos = cpos+1
        return data:sub(cpos-1,cpos-1)
      end
    end
    id:mapPixel(function(x,y, r,g,b,a)
      local char = nextchar(); local byte = string.byte(char)
      local rb, gb, bb, ab = band(byte,rf), band(byte,gf), band(byte,bf), band(byte,af)
      gb, bb, ab = rshift(gb, 2), rshift(bb, 4), rshift(ab, 6)
      r,g,b,a = bor(r,rb), bor(g,gb), bor(b,bb), bor(a,ab)
      return r,g,b,a
    end)
  return true, id:encode("png"):getString()
  end
  
  --Clear the data from the floppy image.
  function fapi.format(floppypng)
    if type(floppypng) ~= "string" then return false, "Floppy PNG Data must be a string, provided: "..type(floppypng) end
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
    if type(floppypng) ~= "string" then return false, "Floppy PNG Data must be a string, provided: "..type(floppypng) end
    print("reading a floppy")
    local ok,id = devkit.loadImage(floppypng)
    if not ok then return false, "Invalid PNG Data." end
    local data, lstr, dcounter, dlen = {}, {}, 0
    local filter = tonumber(11, 2)
    id:mapPixel(function(x,y, r,g,b,a)
      local rb, gb, bb, ab = band(r,filter), band(g,filter), band(b,filter), band(a,filter)
      gb, bb, ab = lshift(gb,2), lshift(bb,4), lshift(ab,6)
      local byte = bor(rb,gb,bb,ab) print(byte); local char = string.char(byte)
      if not dlen then --Reading data length.
        if char ~= ";" then
          table.insert(lstr,char)
        else --End of data length
          lstr = table.concat(lstr)
          dlen = tonumber(lstr)
        end
      else --Reading data.
        if dcounter < dlen then --InsertData
          table.insert(data,char)
          dcounter = dcounter + 1
        end
      end
      return r,g,b,a
    end)
    data = table.concat(data)
    return true, data, dlen
  end
  
  return fapi, devkit
end