local perpath = select(1,...) --The path to the FDD folder

return function(config)
  
  local sfxr = love.filesystem.load(perpath.."sfxr.lua")()
  
  local au, devkit, indirect = {}, {}, {}
  
  function au.playRandom()
    
    local sound = sfxr.newSound()
    sound:randomize()
    local sounddata = sound:generateSoundData()
    local source = love.audio.newSource(sounddata)
    source:play()
    
    return true
    
  end
  
  return au, devkit, indirect
  
end