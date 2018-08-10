--DiskOS API Loader

local term = require("terminal")
local MainDrive = term.getMainDrive()

local Globals = (...) or {}

Globals.SpriteGroup = SpriteGroup
Globals.isInRect = isInRect
Globals.whereInGrid = whereInGrid
Globals.input = TextUtils.textInput

return Globals