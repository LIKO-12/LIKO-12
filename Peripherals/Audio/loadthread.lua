local perpath, chIn, chOut = ...

require("love.audio")
require("love.sound")

local json = require("Engine.JSON")

local sfxr = love.filesystem.load(perpath.."sfxr.lua")()
local sfx = sfxr.newSound()

while true do
  local job = chIn:demand()
  if not job or job == "stop" then break end
  
  local params = json:decode(job)
  for k1,v1 in pairs(params) do
    if type(v1) == "table" then
      for k2,v2 in pairs(v1) do
        sfx[k1][k2]= v2
      end
    else
      sfx[k1] = v1
    end
  end
  
  local sounddata = sfx:generateSoundData()
  chOut:push(sounddata)
end