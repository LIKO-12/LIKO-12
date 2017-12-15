local perpath = select(1,...) --The path to the FDD folder

return function(config)
  
  local sfxr = love.filesystem.load(perpath.."sfxr.lua")
  
  local au, devkit, indirect = {}, {}, {}
  
  
  
  return au, devkit, indirect
  
end