--Lua code loader

local Globals = (...) or {}
local edata = select(2,...) or {}

Globals._GameCode = edata.luacode

return Globals