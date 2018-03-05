--RAM Utilities.

--Variabes.
local sw,sh = screenSize()

--Localized Lua Library
local unpack = unpack
local floor, ceil, min = math.floor, math.ceil, math.min
local strChar, strByte = string.char, string.byte
local lshift, rshift, bor, band, bxor = bit.lshift, bit.rshift, bit.bor, bit.band, bit.bxor

--The API
local RamUtils = {}

RamUtils.VRAM = 0 --The start address of the VRAM
RamUtils.LIMG = RamUtils.VRAM + (sw/2)*sh --The start address of the LabelImage.
RamUtils.FRAM = RamUtils.LIMG + (sw/2)*sh --The start address of the Floppy RAM.
RamUtils.Null = strChar(0) --The null character

--==Images==--

--Encode an image into binary.
function RamUtils.imgToBin(img,getTable)
  if img:typeOf("GPU.image") then img = img:data() end --Convert the image to imagedata.
  local bin = {}
  local imgW, imgH = img:size()
  local flag = true
  img:map(function(x,y,c)
    x = x + y*imgW + 1
    local byte = bin[ceil(x/2)] or 0
    if flag then
      byte = bor(byte,lshift(c,4))
    else
      byte = bor(byte,c)
    end
    bin[ceil(x/2)] = byte
    flag = not flag
  end)
  if getTable then return bin end
  for k,v in pairs(bin) do
    bin[k] = strChar(v)
  end
  return table.concat(bin)
end

--Load an image from binary.
function RamUtils.binToImg(img,bin)
  local colors, cid = {}, 1
  for i=1,bin:len() do
    local byte = strByte(bin,i)
    local left = band(byte,0xF0)
    colors[cid] = rshift(left,4)
    colors[cid+1] = band(byte,0x0F)
    cid = cid + 2
  end
  cid = 1
  img:map(function(x,y,old)
    local c = colors[cid] or 0
    cid = cid + 1
    return c
  end)
end

--==Maps==--

--Encode a map into binary.
function RamUtils.mapToBin(map,getTable)
  local bin = {}
  local tid = 1
  map:map(function(x,y,tile)
    bin[tid] = min(tile,255)
    tid = tid + 1
  end)
  if getTable then return bin end
  for k,v in pairs(bin) do
    bin[k] = strChar(v)
  end
  return table.concat(bin)
end

--Load a map from binary.
function RamUtils.binToMap(map,bin)
  local len, id = bin:len(), 0
  map:map(function(x,y,tile)
    id = id + 1
    return (id <= len and strByte(bin,id) or 0)
  end)
end

--==Code==--

--Encode code into binary.
function RamUtils.codeToBin(code)
  return math.compress(code,"gzip",9)
end

--Load code from binary.
function RamUtils.binToCode(bin)
  return math.decompress(bin,"gzip",9)
end

--==Extra==--

--Encode a number into binary
function RamUtils.numToBin(num,length,getTable)
  local bytes = {}
  for bnum=1,length do
    bytes[bnum] = band(num,255)
    num = rshift(num,8)
  end
  if getTable then return bytes end
  return strChar(unpack(bytes))
end

--Load a number from binary
function RamUtils.binToNum(bin)
  local number = 0
  for i=1,bin:len() do
    local byte = strByte(bin,i)
    byte = lshift(byte,(i-1)*8)
    number = bor(number,byte)
  end
  return number
end

--Calculate the length of the number in bytes
function RamUtils.numLength(num)
  local length = 0
  while num > 0 do
    num = rshift(num,8)
    length = length + 1
  end
  return length
end

--Create a binary iterator for a string
function RamUtils.binIter(bin)
  local counter = 0
  return function()
    counter = counter + 1
    return strByte(bin,counter)
  end, function()
    return counter
  end
end

--Create a binary writer
function RamUtils.binWriter()
  local bytes, bid, byte, bpos = {}, 1, 0, 0
  return function(bits,count)
    if bits then
      byte = lshift(byte,count)
      byte = bor(byte,bits)
      bpos = bpos + count
      
      if bpos >= 8 then
        local cbyte = rshift(byte,bpos-8)
        byte = bxor(byte,lshift(cbyte,bpos-8))
        bpos = bpos - 8
        bytes[bid] = strChar(cbyte)
        bid = bid + 1
      end
    else --Generate the string
      if bpos > 0 then
        bytes[bid] = strChar(byte)
      end
      
      return table.concat(bytes)
    end
  end
end

--Create a bin reader
function RamUtils.binReader(data)
  local bid, byte, bc = 1, 0, 0
  return function(c)
    if c > bc then
      byte = lshift(byte,8)
      byte = bxor(byte,strByte(data,bid))
      bc = bc + 8
      bid = bid + 1
    end
    
    local bits = rshift(byte,bc-c)
    byte = bxor(byte,lshift(bits,bc-c))
    bc = bc - c
    return bits
  end
end

--Make the ramutils a global
_G["RamUtils"] = RamUtils