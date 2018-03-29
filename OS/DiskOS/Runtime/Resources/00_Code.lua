--Lua code loader

local Globals = (...) or {}

local eapi = require("Editors")

local codeid = eapi.editors.code

local luacode = eapi.leditors[codeid]:export()

Globals._GameCode = luacode

return Globals