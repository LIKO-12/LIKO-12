--The spritesheet loader

local Globals = (...) or {}

local eapi = require("Editors")

--The sprites editor ID
local sprid = eapi.editors.sprite

--Get the sheet image
local sheetImage = image(eapi.leditors[sprid]:exportImage())

--Get the sheet flags
local FlagsData = eapi.leditors[sprid]:getFlags()

--Calculate the sheet dimentions
local sheetW, sheetH = sheetImage:width()/8, sheetImage:height()/8

--Create the Spritesheet object.
local SpriteMap = SpriteSheet(sheetImage,sheetW,sheetH)

Globals.SpriteMap = SpriteMap
Globals.SheetFlagsData = FlagsData

return Globals