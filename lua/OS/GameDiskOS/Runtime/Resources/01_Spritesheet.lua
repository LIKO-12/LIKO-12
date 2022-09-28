--The spritesheet loader

local SpriteSheet = require("Libraries.spritesheet")

local Globals = (...) or {}
local edata = select(2,...) or {}

local sheetData = edata.spritesheet --The spritesheet data string

Globals.SpriteMap = SpriteSheet(sheetData,24,16)

return Globals