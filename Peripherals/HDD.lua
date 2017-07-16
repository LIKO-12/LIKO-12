local events = require("Engine.events")
local coreg = require("Engine.coreg")

local _LuaBCHeader = string.char(0x1B).."LJ"

--A function that calculates the total size of a directory
local function calcSize(dir)
  local total = 0
  local files = love.filesystem.getDirectoryItems(dir)
  for k,filename in ipairs(files) do
    if love.filesystem.isDirectory(dir.."/"..filename) then
      total = total + calcSize(dir.."/"..filename.."/")
    else
      total = total + love.filesystem.getSize(dir.."/"..filename)
    end
  end
  return total
end

return function(config) --A function that creates a new HDD peripheral.
  local devkit = {}
  
  --Pre-init--
  if not love.filesystem.exists("/drives") then love.filesystem.createDirectory("/drives") end --Create the folder that holds virtual drives.
  local drives = {}
  
  function devkit.calcUsage()
    for letter, drive in pairs(drives) do
      drive.usage = calcSize("/drives/"..letter)
    end
  end
  
  --Load the virtual hdds configurations--
  if not config["C"] then config["C"] = 1024*1024 * 12 end --Defaults to 12 Megabyte
  for letter, size in pairs(config) do
    if not love.filesystem.exists("/drives/"..letter) then
      love.filesystem.createDirectory("/drives/"..letter) --Create the drive directory if doesn't exists
    end
    drives[letter] = {size = size, usage = 0}
  end
  
  --The api starts here--
  local HDD = {}
  local ad = "C" --The active drive letter
  
  function devkit.resolve(fname)
    if fname:sub(-2,-1) == ":/" then -- C:/
      fname = fname.."/"
    end
    
    local drive = ad
    
    local d, p = fname:match("(.+):/(.+)")
    if d then
      if not drives[d] then return false, "Drive doesn't exists" end
      path = "/drives/"..d.."/"..(p or "/")
      drive = d
    else
      path = "/drives/"..ad.."/"..fname
    end
    
    return path, drive
  end
  
  --Returns a list of the available drives.
  function HDD.drives()
    local dlist = {}
    for k,v in pairs(drives) do
      dlist[k] = {size=drives[k].size,usage=drives[k].usage}
    end
    return true, dlist
  end
  
  --Sets or gets the current active drive.
  function HDD.drive(letter)
    if letter then
      if type(letter) ~= "string" then return false, "The drive letter must be a string, provided: "..type(letter) end --Error
      if not drives[letter] then return false, "The drive '"..letter.."' doesn't exists" end
      ad = letter --Set the active drive letter.
      return true --It ran successfully
    else
      return true, ad
    end
  end
  
  function HDD.write(fname,data,size)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    if type(data) == "nil" then return false, "Should provide the data to write" end
    local data = tostring(data)
    if type(size) ~= "number" and size then return false, "Size must be a number, provided: "..type(size) end
    local path,d = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    local oldsize = (love.filesystem.exists(path) and love.filesystem.isFile(path)) and love.filesystem.getSize(path) or 0 --Old file size.
    local file,err = love.filesystem.newFile(path,"w")
    if not file then return false,err end --Error
    file:write(data,size) --Write to the file (without saving)
    local newsize = file:getSize() --The size of the new file
    if drives[d].size < ((drives[d].usage - oldsize) + newsize) then file:close() return false, "No more enough space" end --Error
    file:flush() --Save the new file
    file:close() --Close the file
    drives[d].usage = (drives[d].usage - oldsize) + newsize --Update the usage
    return true, newsize
  end
  
  function HDD.append(fname,data,size)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    if type(data) == "nil" then return false, "Should provide the data to write" end
    local data = tostring(data)
    if type(size) ~= "number" and size then return false, "Size must be a number, provided: "..type(size) end
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    local oldsize = (love.filesystem.exists(path) and love.filesystem.isFile(path)) and love.filesystem.getSize(path) or 0 --Old file size.
    local file,err = love.filesystem.newFile(path,"a")
    if not file then return false,err end --Error
    file:write(data,size) --Write to the file (without saving)
    local newsize = file:getSize() --The size of the new file
    if drives[ad].size < ((drives[ad].usage - oldsize) + newsize) then file:close() return false, "No more enough space" end --Error
    file:flush()
    file:close() --Close the file
    --local ok, err = love.filesystem.append(path,data,size)
    --if not ok then return ok, err end
    drives[ad].usage = (drives[ad].usage - oldsize) + newsize --Update the usage
    return true, newsize
  end
  
  function HDD.read(fname,size)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    if type(size) ~= "number" and size then return false, "Size must be a number, provided: "..type(size) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    local data, err = love.filesystem.read(path,size)
    if data then return true,data else return false,err end
  end
  
  function HDD.lines(fname)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    if not love.filesystem.exists(path) then return false, "The file doesn't exists !" end --Error
    if love.filesystem.isDirectory(path) then return false, "Can't read directories !" end --Error
    local it = love.filesystem.lines(path)
    if not it then return false, "Failed to read" end
    return true, it
  end
  
  function HDD.remove(fname)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    local path, d = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    if not love.filesystem.exists(path) then return false, "The file doesn't exists !" end --Error
    local fsize = 0
    if love.filesystem.isDirectory(path) then
      local items = love.filesystem.getDirectoryItems(path)
      if #items > 0 then
        return false, "Can't delete non-empty directories !"
      end
    else
      fsize = love.filesystem.getSize(path)
    end
    local ok = love.filesystem.remove(path)
    if not ok then return false, "Failed to delete" end
    if not love.filesystem.exists("/drives/"..d.."/") then love.filesystem.createDirectory("/drives/"..d.."/") end
    drives[d].usage = drives[d].usage - fsize --Update the size
    return true
  end
  
  function HDD.load(fname)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    if not love.filesystem.exists(path) then return true, false, "File doesn't exists ("..tostring(fname)..")" end
    local data = love.filesystem.read(path)
    if data and data:sub(1,3) == _LuaBCHeader then return false, "LOADING BYTECODE IS NOT ALLOWED, YOU HACKER !" end
    local ok, chunk, err = pcall(love.filesystem.load, path)
    if not ok then return true, ok, chunk end
    if not chunk then return true, chunk, err end
    coreg:sandbox(chunk)
    return true, chunk
  end
  
  function HDD.size(fname)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    return love.filesystem.getSize(path)
  end
  
  function HDD.exists(fname)
    if type(fname) ~= "string" then return false, "File/Folder name must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    return true, love.filesystem.exists(path)
  end
  
  function HDD.newDirectory(fname)
    if type(fname) ~= "string" then return false, "Directory name must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    return love.filesystem.createDirectory(path)
  end
  
  function HDD.isFile(fname)
    if type(fname) ~= "string" then return false, "Filename must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    if not love.filesystem.exists(path) then return false, "The file doesn't exists" end --Error
    return true, love.filesystem.isFile(path)
  end
  
  function HDD.isDirectory(fname)
    if type(fname) ~= "string" then return false, "Directory name must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    if not love.filesystem.exists(path) then return false, "The folder doesn't exists" end --Error
    return true, love.filesystem.isDirectory(path)
  end
  
  function HDD.directoryItems(fname)
    if type(fname) ~= "string" then return false, "Foldername must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    if not love.filesystem.exists(path) then return false, "Folder doesn't exists" end --Error
    if not love.filesystem.isDirectory(path) then return false, "Provided a path to a file instead of a folder" end --Error
    return true, love.filesystem.getDirectoryItems(path)
  end
  
  function HDD.lastModified(fname)
    if type(fname) ~= "string" then return false, "File/Folder name must be a string, provided: "..type(fname) end --Error
    local path = devkit.resolve(fname); if not path then return false, "Drive doesn't exists" end
    local modtime, err = love.filesystem.getLastModified(path)
    if not modtime then return false, err else return true, modtime end
  end
  
  devkit.drives = drives
  
  return HDD, devkit
end
