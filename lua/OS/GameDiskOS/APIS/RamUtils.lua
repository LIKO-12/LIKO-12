--RAM Utilities.

--Variabes.
local sw,sh = screenSize()

--The API
local RamUtils = {}

RamUtils.VRAM = 0 --The start address of the VRAM
RamUtils.LIMG = RamUtils.VRAM + (sw/2)*sh --The start address of the LabelImage.
RamUtils.FRAM = RamUtils.LIMG + (sw/2)*sh --The start address of the Floppy RAM.

--Make the ramutils a global
_G["RamUtils"] = RamUtils