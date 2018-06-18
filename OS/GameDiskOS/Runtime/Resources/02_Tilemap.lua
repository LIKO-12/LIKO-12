--The tilemap loader

local Globals = (...) or {}
local edata = select(2,...) or {}

local mapobj = require("Libraries.map")

local swidth, sheight = screenSize()

local mapData = edata.tilemap or ""
local mapW, mapH = swidth*0.75, sheight
local TileMap = mapobj(mapW,mapH,Globals.SpriteMap)
TileMap:import(mapData)

Globals.TileMap = TileMap
Globals.MapObj = mapobj

return Globals