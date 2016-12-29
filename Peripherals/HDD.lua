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
  local ad = "C" --The active drive letter
  
  --Returns a list of the available drives.
  function HDD.drivers()
    local dlist = {}
    for k,v in ipairs(drives) do
      dlist[k] = {size=drives[k].size,usage=drives[k].usage}
    end
    return true,dlist
  end
  
  --Sets or gets the current active drive.
  function HDD.drive(letter)
    if letter then
      if type(letter) ~= "string" then return false, "The drive letter must be a string, provided: "..type(letter) end --Error
      ad = letter --Set the active drive letter.
    else
      return ad
    end
  end
  
  function HDD.write(fname,data,size)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    if type(data) == "nil" then return false, "Should provide the data to write" end
    local data = tostring(data)
    if type(size) ~= "number" and size then return false, "Size must be a number, provided: "..type(size) end
    local path = "/drives/"..ad.."/"..fname
    local oldsize = (love.filesystem.exists(path) and love.filesystem.isFile(path)) and love.filesystem.getSize(path) or 0 --Old file size.
    local file,err = love.filesystem.newFile(path,"w")
    if not file then return false,err end --Error
    file:write(data,size) --Write to the file (without saving)
    local newsize = file:getSize() --The size of the new file
    if drives[ad].size < ((drives[ad].usage - oldsize) + newsize) then file:close() return false, "No more enough space" end --Error
    file:flush() --Save the new file
    file:close() --Close the file
    return true, newsize
  end
  
  function HDD.read(fname,size)
     if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
     if type(size) ~= "number" and size then return false, "Size must be a number, provided: "..type(size) end
     local data, err = love.filesystem.read("/drives/"..ad.."/"..fname,size)
     if data then return true,data else return false,err enx
  end
  
  return HDD
end