--The tilemap loader

local Globals = (...) or {}

local eapi = require("Editors")

local mapobj = require("Libraries/map")

local swidth, sheight = screensize()

local tileid = eapi.editors.tile

local mapData = eapi.leditors[tileid]:export()
local mapW, mapH = swidth*0.75, sheight
local TileMap = mapobj(mapW,mapH,Globals.SpriteMap)
TileMap:import(mapData)

Globals.TileMap = TileMap
Globals.MapObj = mapobj

return Globals