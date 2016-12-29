local events = require("Engine.events")

--A function that calculates the total size of a directory
local function calcSize(dir)
  local total = 0
  local files = love.filesystem.getDirectoryItems(dir)
  for k,filename in ipairs(files) do
    if love.filesystem.isDirectory(dir..filename) then
      total = total + calcSize(path..filename.."/")
    else
      total = total + love.filesystem.getSize(dir..filename)
    end
  end
  return total
end

return function(config) --A function that creates a new HDD peripheral.
  --Pre-init--
  if not love.filesystem.exists("/drives") then love.filesystem.createDirectory("/drives") end --Create the folder that holds virtual drives.
  local drives = {}
  
  --Load the virtual hdds configurations--
  for letter, size in pairs(config) do
    if not love.filesystem.exists("/drives/"..letter) then
      love.filesystem.createDirectory("/drives/"..letter) --Create the drive directory if doesn't exists
      drives[letter] = {size = size, usage = 0} --It's a new empty drive !
    else 
      drives[letter] = {size = size, usage = calcSize("/drives/"..letter)} --Register the drive
    end
  end
  
  --The api starts here--
  local HDD = {}
  
  --Returns a list of the available drives.
  function HDD.drivers()
    
  end
  
  return HDD
end