--RAM Utilities.

--Variabes.
local sw,sh = screenSize()

--Localized Lua Library
local floor = math.floor
local lshift, rshift = bit.lshift, bit,rshift

--The API
local RamUtils = {}

RamUtils.VRAM = 0 --The start address of the VRAM
RamUtils.LIMG = RamUtils.VRAM + (sw/2)*sh --The start address of the LabelImage.
RamUtils.FRAM = RamUtils.LIMG + (sw/2)*sh --The start address of the Floppy RAM.

--Encode an image into binary.
function RamUtils.imgToBin(img,getTable)
  if image:typeOf("GPU.image") then image = image:data() end --Convert the image to imagedata.
  local bin = {}
  local imgW, imgH = img:size()
  local flag = true
  img:map(function(x,y,c)
    x = x + (y-1)*imgW
    local byte = bin[floor((x+1)/2)] or 0
    if flag then
      byte = byte + lshift(c,4)
    else
      byte = byte + c
    end
    flag = not flag 
  end)
  if getTable then return bin end
  return string.char(unpack(bin))
end