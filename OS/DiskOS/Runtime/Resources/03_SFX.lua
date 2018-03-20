--The sound effects loader

local Globals = (...) or {}

local eapi = require("Editors")

local sfxobj = require("Libraries/sfx")

local sfxid = eapi.editors.sfx

local sfxData = eapi.leditors[sfxid]:export():gsub("\n","")
local SFXList, SFXListPos = {}, 0
for sfxstr in sfxData:gmatch("(.-);") do
  local s = sfxobj(32)
  s:import(sfxstr..",")
  SFXList[SFXListPos] = s
  SFXListPos = SFXListPos + 1
end

Globals.SFXS = SFXList
Globals.SfxObj = sfxobj

return Globals