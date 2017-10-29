--RAM Utilities.

--Variabes.
local sw,sh = screenSize()

--Localized Lua Library
local floor, ceil, min = math.floor, math.ceil, math.min
local strChar, strByte = string.char, string.byte
local lshift, rshift, bor, band = bit.lshift, bit,rshift, bit.bor, bit.band

--The API
local RamUtils = {}

RamUtils.VRAM = 0 --The start address of the VRAM
RamUtils.LIMG = RamUtils.VRAM + (sw/2)*sh --The start address of the LabelImage.
RamUtils.FRAM = RamUtils.LIMG + (sw/2)*sh --The start address of the Floppy RAM.

--==Images==--

--Encode an image into binary.
function RamUtils.imgToBin(img,getTable)
  if image:typeOf("GPU.image") then image = image:data() end --Convert the image to imagedata.
  local bin = {}
  local imgW, imgH = img:size()
  local flag = true
  img:map(function(x,y,c)
    x = x + y*imgW + 1
    local byte = bin[floor(x/2)] or 0
    if flag then
      byte = byte + lshift(c,4)
    else
      byte = byte + c
    end
    bin[floor(x/2)] = byte
    flag = not flag
  end)
  if getTable then return bin end
  return strChar(unpack(bin))
end

--Load an image from binary.
function RamUtils.binToImage(img,bin)
  local colors, cid = {}, 1
  for i=1,bin:len() do
    local byte = strByte(bin,i)
    local left = band(byte,0xF0)
    colors[cid] = rshift(left,4)
    colors[cid+1] = band(byte,0x0F)
    cid = cid + 2
  end
  cid = 1
  imgdata:map(function(x,y,c)
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
  return strChar(unpack(bin))
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