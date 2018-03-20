--Lua code loader

local Globals = (...) or {}

local eapi = require("Editors")

local codeid = eapi.editors.code

local luacode = eapi.leditors[codeid]:export()
luacode = luacode .. "\n__".."_autoEventLoop()" --Because trible _ are not allowed in LIKO-12

Globals._GameCode = luacode

return Globals