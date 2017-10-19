--Advanced RAM API

--[[

--RAM PLAN--

- MetaData (1 KB)
- DiskData (63 KB)
---
- Persistant Data (2 KB)
- GPIO (128 Bytes)
- Reserved (768 Bytes)
- Draw State (64 Bytes)
- Reserved (64 Bytes)
- Free Space (1 KB)
- Reserved (4 KB)
- Label Image (12 KBytes)
- VRAM (12 KBytes)

--Meta Data--

- Header -> LK12;OSData;DiskOS;GameDisk;Bin; -> 32 byte
- DiskVersion -> 1 Byte
- APIVersion -> 1 Byte
- AuthorName -> 16 Bytes.
- GameName -> 16 Bytes.
- DISK META -> 1 Packed Byte.

--Editors Data--
-- [EDITORID] \0 [DataSize] 2 bytes, [METASIZE] (Tokenized) \0 [THE METADATA]

--Disk META--
[1] Licensed Under CC0.
[2] Write Protection.
[3] Edit Protection.
[4] Auto Event Loop
[5] + [6] + [7] -> Language (Lua, Lisp, Moonscript, ASM, MetaLua)
[6] ^
[7] ^
[8] Mobile Friendly

]]

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

local MapObj = require("Libraries/map")
local UnallocatedRam = 1024*63+256

RAM.Resources = {} --A table of the available resources.
RAM.IResources = {} --A table of initialized resources.
RAM.DiskDataID = 0
RAM.DiskDataSize = 1024*64 - 736

--A function to convert from kilobytes into bytes, a SyntaxSugar.
local function KB(v) return v*1024 end

--Initialize the RAM
function RAM:initialize()
  --Remove any existing sections--
  local sections = self._getSections()
  for i=1,#sections do self._removeSection() end
  
  local Layout = {
    {736},    --[1] 0x0000 Meta Data (736 Bytes)
    {KB(64)-736}, --[2]    DiskData
    {KB(20)}, --[3] 0xB000 Compressed Lua Code (20 KB)
    {KB(02)}, --[4] 0x10000 Persistant Data (2 KB)
    {128},    --[5] 0x10800 GPIO (128 Bytes)
    {768},    --[6] 0x10880 Reserved (768 Bytes)
    {64},     --[7] 0x10B80 Draw State (64 Bytes)
    {64},     --[8] 0x10BC0 Reserved (64 Bytes)
    {KB(01)}, --[9] 0x10C00 Free Space (1 KB)
    {KB(04)}, --[10] 0x11000 Reserved (4 KB)
    {KB(12)}, --[11] 0x12000 Label Image (12 KBytes)
    {KB(12),"VRAM"}  --[12] 0x15000 VRAM (12 KBytes)
  }
  
  --Some reference variables for use later when creating Resources.
  self.DiskDataID = 2
  self.DiskDataSize = KB(64)-736
  
  --LabelImage Handler
  self.LabelImage = imageData(sw,sh)
  self.LabelHandler = self.newImageHandler(self.LabelImage)
  Layout[11] = self.LabelHandler
  
  --Create the new sections--
  for id, data in ipairs(Layout) do
    self._newSection(data[1], data[2])
  end
end

--[[ Create a new RAM resource type.
name (string): The name of the resource.
type (string or nil): The type of the resource, defaults to 'unknown'.
subtype (sting or nil): The subtype of the resource, defaults to ''.
steps (number or nil): The number of space steps, nil for infinity.
calcSize (function or nil): Calculate the required space provided a step number.
unit (function or nil): Return the name of the mesuring unit, defaults to 'bytes'.
enable (function): Clame the wanted resources and register some handlers.
disable (function): Revert changes made by the enable function.]]
function RAM:newResource(name,rtype,subtype,steps,calcSize,unit,enable,disable)
  local rtype, subtype = rtype or "unknown", subtype or ""
  local calcSize = calcSize or function(s)
    if s >= 1024 then
      return (s-1023)*1024
    else
      return s
    end
  end
  local unit = unit or function(st,sz)
    if s >= 1024 then
      return "KB", (s-1023)
    else
      return "Byte", s
    end
  end
  if type(name) ~= "string" then return error("Resource Name must be a string, provided: "..type(name)) end
  if type(rtype) ~= "string" then return error("Resource Type must be a string or a nil, provided: "..type(rtype)) end
  if type(subtype) ~= "string" then return error("Resource SubType must be a string or a nil, provided: "..type(subtype)) end
  if steps and type(steps) ~= "number" then return error("Resource size steps must be a number or a nil, provided: "..type(steps)) end
  if type(calcSize) ~= "function" then return error("Resource CalcSize must be a function or a nil, provided: "..type(calcSize)) end
  if type(unit) ~= "function" then return error("Resource unit must be a function or a nil, provided: "..type(unit)) end
  if type(enable) ~= "function" then return error("Resource enable must be a function, provided: "..type(enable)) end
  if type(disable) ~= "function" then return error("Resource disable must be a function, provided: "..type(disable)) end
  
  if self.Resources[name] then return error("Resource '"..name.."' already exists !") end
  self.Resources[name] = {
    name = name,
    type = rtype,
    subtype = subtype,
    steps = steps or false,
    calcSize = calcSize,
    unit = unit,
    enable = enable,
    disable = disable
  }
  return self, self.Resources[name]
end

--Create/Inilialize/Allocate a resource.
function RAM.createResource(name,steps)
  if type(name) ~= "string" then return error("Resource Name must be a string, provided: "..type(name)) end
  if type(steps) ~= "number" then retuen error("Resource Size Steps must be a number, provided: "..type(steps)) end
end

--Create a new RAM handler for an imagedata.
function RAM:newImageHandler(img)
  local imgline = img:width()/2 --The size of each image line in bytes.
  local imgsize = imgline * img:height() --The size of the image in bytes.
  local imgWidth, imgHeight = img:size()
  
  local imgline4, imgsize4 = imgline * 2, imgsize * 2 --For peek4 and poke4
  
  local changed = false --Is there any changes applied on the image ?
  
  local function hand(mode,startAddress,address,...)
    --cprint("IMAGE HAND",mode,startAddress,address,...)
    
    if mode == "changed" then
      if changed then
        changed = false
        return true
      else
        return false
      end
    end
    
    local address = address - startAddress
    
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
      img:setPixel(x+1,y,rpix)
      
      --Update Changed Flag
      changed = true
      
    elseif mode == "poke4" then
      local pix = ...
      
      --Calculate the position of the left pixel
      local x = address % imgline4
      local y = math.floor(address / imgline4)
      
      --Set the pixels
      img:setPixel(x,y,pix)
      
      --Update Changed Flag
      changed = true
      
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
      
    elseif mode == "peek4" then
      --Calculate the position of the left pixel
      local x = address % imgline4
      local y = math.floor(address / imgline4)
      
      --Return the pixel color
      return img:getPixel(x,y)
      
    elseif mode == "memget" then
      local length = ...
      
      local x = (address % imgline) * 2
      local y = math.floor(address / imgline)
      
      local xStart, data = x, ""
      
      for Y = y, imgHeight-1 do
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
      local data = ...
      local length = data:len()
      
      local x = (address % imgline) * 2
      local y = math.floor(address / imgline)
      
      local iter = string.gmatch(data,".")
      
      for i=1,length do
        
        local char = iter()
        local pix = string.byte(char)
        
        local lpix = band(pix,0xF0)
        local rpix = band(pix,0x0F)
        
        lpix = rshift(lpix,4)
        
        img:setPixel(x,y,lpix)
        img:setPixel(x+1,y,rpix)
        
        x = x+2
        
        if x >= imgWidth then
          x = x - imgWidth
          y = y+1
        end
        
      end
      
      --Update Changed Flag
      changed = true
      
    elseif mode == "memcpy" then
      local toAddress, length = ...
      
      local addressEnd = address+length-1
      local toAddressEnd = toAddress+length-1
      
      for line0=0,imgsize,imgline do
        local line0End = line0+imgline-1
        
        if addressEnd >= line0 and address <= line0End then
          local sa1 = (address < line0) and line0 or address
          local ea1 = (addressEnd > line0End) and line0End or addressEnd
          
          local toAddress = toAddress + (sa1 - address)
          local toAddressEnd = toAddressEnd + (ea1 - addressEnd)
          
          for line1=0,imgsize,imgline do
            local line1End = line1+imgline-1
            
            if toAddressEnd >= line1 and toAddress <= line1End then
              local sa2 = (toAddress < line1) and line1 or toAddress
              local ea2 = (toAddressEnd > line1End) and line1End or toAddressEnd
              
              local address = address + (sa2 - toAddress)
              local addressEnd = addressEnd + (ea2 - toAddressEnd)
              
              local len = addressEnd - address + 1
              
              local fromX = (address % imgline) * 2
              local fromY = math.floor(address / imgline)
              
              local toX = (sa2 % imgline) * 2
              local toY = math.floor(sa2 / imgline)
              
              img:paste(img,toX,toY,fromX,fromY,len*2,1)
            end
          end
        end
      end
      
      --Update Changed Flag
      changed = true
    end
  end
  
  return hand
end

function RAM:newMapHandler(map)
  local mapline = map:width() --The size of each map line in bytes.
  local mapsize = mapline * map:height() --The size of the map in bytes.
  local mapWidth, mapHeight = map:size()
  
  local mapline4, mapsize4 = mapline * 2, mapsize * 2 --For peek4 and poke4
  
  local function hand(mode,startAddress,address,...)
    local address = address - startAddress
    
    if mode == "poke" then
      local tile = ...
      
      --Calculate the position of the tile
      local x = address % mapline
      local y = math.floor(address / mapline)
      
      --Set the tile
      map:cell(x,y,tile)
      
    elseif mode == "poke4" then
      local tile = ...
      
      --Calculate the position of the tile
      local x = address % mapline4
      local y = math.floor(address / mapline4)
      
      --Get the tile byte
      local byte = map:cell(x,y)
      
      --Replace the poked nibble
      if address % 2 == 0 then --Left nibble
        byte = bit.band(byte,0x0F)
        tile = bit.lshift(tile,4)
        byte = bit.bor(byte,tile)
      else --Right nibble
        byte = bit.band(byte,0xF0)
        byte = bit.bor(byte,tile)
      end
      
      --Set the new tile value
      map:cell(x,y,byte)
      
    elseif mode == "peek" then
      --Calculate the position of the tile
      local x = address % mapline
      local y = math.floor(address / mapline)
      
      --Return the tile
      return map:cell(x,y)
      
    elseif mode == "peek4" then
      --Calculate the position of the tile
      local x = address % mapline4
      local y = math.floor(address / mapline4)
      
      --Get the tile byte
      local byte = map:cell(x,y)
      
      --Return the wanted nibble
      if address % 2 == 0 then --Left nibble
        return bit.rshift(byte,4)
      else --Right nibble
        return bit.band(byte,0x0F)
      end
      
    elseif mode == "memget" then
      --Requires verification.
      local length = ...
      
      local x = address % mapline
      local y = math.floor(address / mapline)
      
      local xStart, data = x, ""
      
      for Y = y, mapHeight-1 do
        for X = xStart, mapWidth-1 do
          
          local tile = map:cell(x,y)
          local char = string.char(tile)
          
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
      
      local x = address % mapline
      local y = math.floor(address / mapline)
      
      local iter = string.gmatch(data,".")
      
      for i=1,length do
        
        local char = iter()
        local tile = string.byte(char)
        
        map:cell(x,y,tile)
        
        x = x + 1
        
        if x >= mapWidth then
          x = x - mapWidth
          y = y + 1
        end
        
      end
      
    elseif mode == "memcpy" then
      local toAddress, length = ...
      
      local addressEnd = address+length-1
      local toAddressEnd = toAddress+length-1
      
      for line0=0,mapsize,mapline do
        local line0End = line0+mapline-1
        
        if addressEnd >= line0 and address <= line0End then
          local sa1 = (address < line0) and line0 or address
          local ea1 = (addressEnd > line0End) and line0End or addressEnd
          
          local toAddress = toAddress + (sa1 - address)
          local toAddressEnd = toAddressEnd + (ea1 - addressEnd)
          
          for line1=0,mapsize,mapline do
            local line1End = line1+mapline-1
            
            if toAddressEnd >= line1 and toAddress <= line1End then
              local sa2 = (toAddress < line1) and line1 or toAddress
              local ea2 = (toAddressEnd > line1End) and line1End or toAddressEnd
              
              local address = address + (sa2 - toAddress)
              local addressEnd = addressEnd + (ea2 - toAddressEnd)
              
              local len = addressEnd - address + 1
              
              local fromX = (address % mapline) * 2
              local fromY = math.floor(address / mapline)
              
              local toX = (sa2 % mapline) * 2
              local toY = math.floor(sa2 / mapline)
              
              for i=0, len-1 do
                map:cell(toX+i,toY,map:cell(fromX+i,fromY))
              end
            end
          end
        end
      end
    end
  end
  
  return hand
end

RAM:initialize()
