--Advanced RAM API

--The RAM table is created by boot.lua, It's the peripheral table.
if not RAM then return end --Incase if the RAM peripheral is disabled.
--Make the non-system functions as globals
for k,v in pairs(RAM) do
  if k:sub(1,1) ~= "_" then
    _G[k] = v
  end
end

--Localize the bit api for better perfromance.
local band, bor, bxor, lshift, rshift = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift

local sw,sh = screenSize()

--A function to convert from kilobytes into bytes, a SyntaxSugar.
local function KB(v) return v*1024 end

local InitLayout = {
  {736},    --0x0000 Meta Data (736 Bytes)
  {KB(12)}, --0x02E0 SpriteMap (12 KB)
  {288},    --0x32E0 Flags Data (288 Bytes)
  {KB(18)}, --0x3400 MapData (18 KB)
  {KB(13)}, --0x7C00 Sound Tracks (13 KB)
  {KB(20)}, --0xB000 Compressed Lua Code (20 KB)
  {KB(02)}, --0x10000 Persistant Data (2 KB)
  {128},    --0x10800 GPIO (128 Bytes)
  {768},    --0x10880 Reserved (768 Bytes)
  {64},     --0x10B80 Draw State (64 Bytes)
  {64},     --0x10BC0 Reserved (64 Bytes)
  {KB(01)}, --0x10C00 Free Space (1 KB)
  {KB(04)}, --0x11000 Reserved (4 KB)
  {KB(12)}, --0x12000 Label Image (12 KBytes)
  {KB(12),"VRAM"}  --0x15000 VRAM (12 KBytes)
}

--Initialize the RAM
function RAM.initialize()
  --Remove any existing sections
  local sections = _getSections()
  for i=#sections,1,-1 do _removeSection(i) end
  
  --Create the new sections
  for id, data in ipairs(InitLayout) do
    _newSection(data[1], data[2])
  end
end

--Create a new RAM handler for an imagedata.
function RAM.newImageHandler(img)
  local imgline = img:width()/2 --The size of each image line in bytes.
  local imgsize = imgline * img:height() --The size of the image in bytes.
  local imgWidth, imgHeight = img:size()
  
  local changed = false --Is there any changes applied on the image ?
  
  local function hand(mode,startAddress,address,...)
    local address = address - startAddress +1
    
    if mode == "poke" then
      local pix = ...
      
      --Calculate the position of the left pixel
      local x = (address % imgline) * 2
      local y = math.floor(address / imgline)
      
      --Separate the 2 pixels from each other
      local lpix = band(pix,0xF0)
      local rpix = band(pix,0x0F)
      
      --Shift the left pixel
      lpix = rshift(lpix,4)
      
      --Set the pixels
      img:setPixel(x,y,lpix)
      img:setPixel(x,y,rpix)
      
    elseif mode == "peek" then
      --Calculate the position of the left pixel
      local x = (address % imgline) * 2
      local y = math.floor(address / imgline)
      
      --Get the colors of the 2 pixels
      local lpix = img:getPixel(x,y)
      local rpix = img:getPixel(x+1,y)
      
      --Shift the left pixel.
      lpix = lshift(lpix,4)
      
      --Merge the 2 pixels into 1 byte.
      local pix = bor(lpix,rpix)
      
      --Return the final result
      return pix
      
    elseif mode == "memget" then
      --Requires verification.
      local length = ...
      
      local x = (address % imgline) * 2
      local y = math.floor(address / imgline)
      
      local xStart, data = x, ""
      
      for Y = y, imgHeight-1, 2 do
        for X = xStart, imgWidth-1, 2 do
          
          local lpix = img:getPixel(X,Y)
          local rpix = img:getPixel(X+1,Y)
          
          lpix = lshift(lpix,4)
          
          local pix = bor(lpix,rpix)
          local char = string.char(pix)
          
          data = data .. char
          
          length = length -1
          
          if length == 0 then
            return data
          end
          
        end
        xStart = 0 --Trick
      end
      
      return data
      
    elseif mode == "memset" then
      --Requires verification.
      local data = ...
      local length = data:len()
      
      local x = (address % imgline - 1) * 2
      local y = math.floor(address / imgline) - 1
      
      local iter = string.gmatch(data,".")
      
      for i=1,length do
        
        x = (x+2) % (imgWidth-1)
        y = y+1
        
        local char = iter()
        local pix = string.byte(char)
        
        local lpix = band(pix,0xF0)
        local rpix = band(pix,0x0F)
        
        lpix = rshift(lpix,4)
        
        img:setPixel(x,y,lpix)
        img:setPixel(x+1,y,rpix)
        
      end
      
    elseif mode == "memcpy" then
      
    end
  end
end

return RAM