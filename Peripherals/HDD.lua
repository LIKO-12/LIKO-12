local events = require("Engine.events")
local coreg = require("Engine.coreg")

local _LuaBCHeader = string.char(0x1B).."LJ"

--Helping functions
--A usefull split function
local function split(inputstr, sep)
  if sep == nil then sep = "%s" end
  local t={} ; i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end

local function lastIndexOf(str,of)
  local lastIndex = 0
  local lastEnd = 0
  while true do
    local cstart,cend = string.find(str,of,lastEnd+1)
    if cstart then
      lastIndex, lastEnd = cstart, cend
    else
      break
    end
  end
  
  return lastIndex
end

local function indexOf(str,of)
  local cstart,cend = string.find(str,of)
  if cstart then return cstart else return 0 end
end

--Value, expected Type, Variable Name
local function Verify(v,t,n)
  if type(v) ~= t then
    error(n.." should be a "..t.." provided: "..type(v),3)
  end
end

return function(Config)
  local RootDir = Config.RootDir or "/drives/"
  local Drives, ActiveDrive = {}
  
  --Create the drives root directory if it doesn't exists.
  if not love.filesystem.exists(RootDir) then
    love.filesystem.createDirectory(RootDir)
  end
  
  --Create the virtual drives
  for name, size in pairs(Config.Drives or {C=2*1024*1024}) do
    if not love.filesystem.exists(RootDir..name) then
      love.filesystem.createDirectory(RootDir..name)
    end
    
    ActiveDrive = ActiveDrive or name
    Drives[name] = {Size=size, Usage=0}
  end
  
  local fs, yfs, devkit = {}, {}, {}
  
  --Helping functions
  local function sanitizePath(path,ignoreActiveDrive,wild,skipDriveCheck)
    --Allow windowsy slashes
    path = path:gsub("\\","/")
    
    if path:sub(-2,-1) == ":/" then path = path.."/" end --(C:/)
    
    --Parse the drive name (if provided) ([driveName]:/[path])
    local drive = (not ignoreActiveDrive) and ActiveDrive or false
    local d, p = path:match("(.+):/(.+)")
    if d then
      if (not Drives[d]) and (not skipDriveCheck) then error("Drive '"..d.."' doesn't exists !",3) end
      drive, path = d, p
    end
    
    --Clean the path from illegal characters.
    local specialChars = {
      "\"", ":", "<", ">", "%?", "|" --Sorted by ascii value (important)
    }
    
    if not wild then table.insert(specialChars,"%*") end
    
    for k, char in ipairs(specialChars) do
      path = path:gsub(char,"")
    end
    
    --Collapse the string into its component parts, removing ..'s
    local parts = split(path,"/")
    local output = {}
    for k, part in ipairs(parts) do
      if part:len() > 0 and part ~= "." then
        
        if part == ".." or part == "..." then
          --.. or ... can cancel out the last folder entered
          if #output > 0 and output[#output] ~= ".." then
            output[#output] = nil
          else
            table.insert(output,"..")
          end
        elseif part:len() > 255 then
          --If part length > 255 and it is the last part
          table.insert(output,part:sub(1,255))
        else
          --Anyhing else we add to the stack
          table.insert(output,part)
        end
        
      end
    end
    
    --Recombine the output parts into a new string
    return table.concat(output,"/"), drive
  end
  
  --NOTE: The path should include the drive folder (eg C:/ex -> C/ex)
  local function createPath(path)
    local parts = split(path,"/")
    local totalPath = ""
    for k, part in ipairs(parts) do
      totalPath = totalPath.."/"..part
      
      if love.filesystem.exists(RootDir..totalPath) then
        if love.filesystem.isFile(RootDir..totalPath) then
          error("Can't create a directory in a file !",3)
        end
      else
        love.filesystem.createDirectory(RootDir..totalPath)
      end
    end
  end
  
  local function findIn( startDrive, startDir, matches, wildPattern )
    local list = fs.getDirectoryItems(startDrive..":/"..startDir)
    for k, entry in ipairs(list) do
      local entryPath = (startDir:len() == 0) and entry or startDir.."/"..entry
      if string.match(entryPath, wildPattern) then
        table.insert(matches,entryPath)
      end
      
      if fs.isDirectory(startDrive..":/"..entryPath) then
        findIn( startDrive, entryPath, matches, wildPattern )
      end
    end
  end
  
  --NOTE: The from and to should include the drive folder (eg C:/ex -> C/ex)
  local function copyRecursive(from, to)
    if not love.filesystem.exists(RootDir..from) then return end
    
    if love.filesystem.isDirectory(RootDir..from) then
      --Copy a directory:
      --Make the new directory
      love.filesystem.newDirectory(RootDir..to)
      
      --Copy the source contents into it
      local files = love.filesystem.getDirectoryItems(RootDir..from)
      for k,file in ipairs(files) do
        copyRecursive(
          fs.combine(from,file),
          fs.combine(to,file)
        )
      end
    else
      --Copy a file
      local data = love.filesystem.read(RootDir..from)
      love.filesystem.write(RootDir..to,data)
    end
  end
  
  --NOTE: The from and to should include the drive folder (eg C:/ex -> C/ex)
  local function deleteRecursive(path)
    if not love.filesystem.exists(RootDir..path) then return end
    
    if love.filesystem.isDirectory(RootDir..path) then
      --Delete a directory:
      
      local files = love.filesystem.getDirectoryItems(RootDir..path)
      for k,file in ipairs(files) do
        deleteRecursive(fs.combine(path,file))
      end
      
      love.filesystem.remove(RootDir..path) --Delete the directory
    else
      --Delete a file
      
      love.filesystem.remove(RootDir..path)
    end
  end
  
  --NOTE: The path should include the drive folder (eg C:/ex -> C/ex)
  local function getSizeRecursive(path)
    if not love.filesystem.exists(RootDir..path) then return 0 end
    
    if love.filesystem.isDirectory(RootDir..path) then
      --Index a directory:
      local total = 0
      local files = love.filesystem.getDirectoryItems(RootDir..path)
      for k,file in ipairs(files) do
        total = total + getSizeRecursive(path.."/"..file)
      end
      return total
    else
      return love.filesystem.getSize(RootDir..path)
    end
  end
  
  --NOTE: The path should include the drive folder (eg C:/ex -> C/ex)
  local function getLastModifiedRecursive(path)
    if love.filesystem.isDirectory(RootDir..path) then
      --Index a directory:
      local latest = 0
      local files = love.filesystem.getDirectoryItems(RootDir..path)
      for k,file in ipairs(files) do
        local lastMod, err = getSizeRecursive(path.."/"..file)
        if lastMod then
          if lastMod > latest then latest = lastMod end
        else
          print("LastModified Err",err)
        end
      end
      
      if latest == 0 then
        return false, "Directory Empty"
      else
        return latest
      end
    else
      return love.filesystem.getLastModified(RootDir..path)
    end
  end
  
  --NOTE: The path should be in [driveName]:/[path] format !
  local function recurse_spec(results, path, spec)
    local segment = spec:match('([^/]*)'):gsub('/', '')
    local pattern = '^' .. segment:gsub("[%.%[%]%(%)%%%+%-%?%^%$]","%%%1"):gsub("%z","%%z"):gsub("%*","[^/]-") .. '$'

    if fs.isDir(path) then
      for _, file in ipairs(fs.list(path)) do
        if file:match(pattern) then
          local f = fs.combine(path, file)

          if spec == segment then
            table.insert(results, f)
          end
          if fs.isDir(f) then
            recurse_spec(results, f, spec:sub(#segment + 2))
          end
        end
      end
    end
  end
  
  --APIS
  
  --Returns a list of the available drives.
  function fs.drives()
    local dlist = {}
    for k,v in pairs(Drives) do
      dlist[k] = {size=Drives[k].Size,usage=Drives[k].Usage}
    end
    return dlist
  end
  
  --Set or get the current active drive.
  function fs.drive(name)
    if name then
      Verify(name,"string","Drive Name")
      
      if not Drives[name] then return error("Drive '"..name.."' doesn't exist !") end
      
      ActiveDrive = name
    else
      return ActiveDrive
    end
  end
  
  --Sanitize a path
  function fs.sanitizePath(path,ignoreActiveDrive,wild)
    Verify(path,"string","Path")
    
    return sanitizePath(path,ignoreActiveDrive,wild,true)
  end
  
  --List directory items.
  function fs.getDirectoryItems(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if not love.filesystem.exists(RootDir..path) then return error("Folder doesn't exists !") end
    if love.filesystem.isFile(RootDir..path) then return error("The path must be a directory, not a file !") end
    
    return assert(love.filesystem.getDirectoryItems(RootDir..path))
  end
  
  --Combine 2 paths.
  function fs.combine(path, childPath)
    Verify(path,"string","Path")
    Verify(childPath,"string","Child Path")
    
    local path, drive = sanitizePath(path,true,true)
    local childPath, childDrive = sanitizePath(childPath,true,true)
    
    if drive and childDrive and drive ~= childDrive then
      return error("The 2 paths has different drives ("..drive.." ~= "..childDrive..")")
    end
    
    if not drive then drive = childDrive end
    
    if drive then
      if path:len() == 0 then
        return drive..":/"..childPath
      elseif childPath:len() == 0 then
        return drive..":/"..path
      else
        return drive..":/"..sanitizePath( path.."/"..childPath, true, true )
      end
    else
      if path:len() == 0 then
        return childPath
      elseif childPath:len() == 0 then
        return path
      else
        return sanitizePath( path.."/"..childPath, true, true )
      end
    end
  end
  
  --Get the last part of the path.
  function fs.getName(path)
    Verify(path,"string","Path")
    
    path = sanitizePath(path,true,true)
    if path:len() == 0 then
      return "root"
    end
    
    local lastSlash = lastIndexOf(path,"/")
    if lastSlash > 0 then
      return path:sub(lastSlash+1,-1)
    else
      return path
    end
  end
  
  --Get the file size.
  function fs.getSize(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    return getSizeRecursive(path)
  end
  
  --Get the file size.
  function fs.getLastModified(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if not love.filesystem.exists(RootDir..path) then return error("File doesn't exists !") end
    
    return getLastModifiedRecursive(RootDir..path)
  end
  
  --Check if a file exists or not.
  function fs.exists(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    return love.filesystem.exists(RootDir..path)
  end
  
  --Check if it's a file or not.
  function fs.isFile(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    if not love.filesystem.exists(RootDir..path) then return false end
    return love.filesystem.isFile(RootDir..path)
  end
  
  --Check if it's a directory or not.
  function fs.isDirectory(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    if not love.filesystem.exists(RootDir..path) then return false end
    return love.filesystem.isDirectory(RootDir..path)
  end
  
  --Create a new directory
  function fs.newDirectory(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    createPath(path)
  end
  
  --FIXME should pay respect to the drive usage ! (When moving files cross drives)
  --Move files/file from path to another (supports directories)
  function fs.move(from,to)
    Verify(from,"string","From Path")
    Verify(to,"string","To Path")
    
    local from, fromDrive = sanitizePath(from); from = fromDrive.."/"..from
    local to, toDrive = sanitizePath(to); to = toDrive.."/"..to
    
    if not love.filesystem.exists(RootDir..from) then return error("From Path doesn't exists !") end
    
    createPath(to)
    
    copyRecursive(from,to)
    deleteRecursive(from)
  end
  
  --Copy files/file from path to another (supports directories)
  function fs.copy(from,to)
    Verify(from,"string","From Path")
    Verify(to,"string","To Path")
    
    local from, fromDrive = sanitizePath(from); from = fromDrive.."/"..from
    local to, toDrive = sanitizePath(to); to = toDrive.."/"..to
    
    if not love.filesystem.exists(RootDir..from) then return error("From Path doesn't exists !") end
    
    local csize = getSizeRecursive(from)
    if Drives[toDrive].Usage + csize > Drives[toDrive].Size then return error("No enough space !") end
    
    createPath(to)
    
    copyRecursive(from,to)
    
    Drives[toDrive].Usage = Drives[toDrive].Usage + csize
  end
  
  --Delete file/files (supports directories)
  function fs.delete(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if not love.filesystem.exists(RootDir..path) then return error("Path doesn't exists !") end
    
    local dsize = getSizeRecursive(path)
    Drives[drive].Usage = Drives[drive].Usage - dsize
    
    deleteRecursive(path)
  end
  
  --Return the remaining free space
  function fs.getFreeSpace(drive)
    
    if drive then Verify(drive,"string","Drive Name") end
    
    local drive = drive or ActiveDrive
    if not Drives[drive] then return error("Drive '"..drive.."' doesn't exist !") end
    
    return Drives[drive].Size-Drives[drive].Usage
  end
  
  --Match files with a specific wildPath, and return their names.
  function fs.find(wildPath)
    Verify(wildPath,"string","wildPath")
    
    local wildPath, wildDrive = sanitizePath(wildPath, false, true)
    local results = {}
    recurse_spec(results,wildDrive..":/",wildPath)
    return results
  end
  
  --Get the directory path of a file
  function fs.getDirectory(path)
    Verify(path,"string","path")
    
    path = sanitizePath(path)
    if path:len() == 0 then return ".." end
    
    local lastSlash = lastIndexOf(path,"/")
    if lastSlash > 0 then
      return path:sub(1,lastSlash)
    else
      return ""
    end
  end
  
  --Get the drive name of a file
  function fs.getDrive(path)
    Verify(path,"string","path")
    
    local path, drive = sanitizePath(path)
    return drive
  end
  
  --Read a file content
  function fs.read(path,size)
    Verify(path,"string","Path")
    if size then Verify(size,"number","Size") end
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if not love.filesystem.exists(RootDir..path) then return error("File doesn't exists.") end
    if love.filesystem.isDirectory(RootDir..path) then return error("Can't read content of a directory.") end
    
    return love.filesystem.read(RootDir..path, size)
  end
  
  --Load a Lua file
  function fs.load(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if not love.filesystem.exists(RootDir..path) then return error("File doesn't exists.") end
    if love.filesystem.isDirectory(RootDir..path) then return error("Can't load content of a directory.") end
    
    local data = love.filesystem.read(RootDir..path)
    if data and data:sub(1,3) == _LuaBCHeader then return error("LOADING BYTECODE IS NOT ALLOWED, YOU HACKER !") end
    
    local ok, chunk, err = pcall(love.filesystem.load, RootDir..path)
    if not ok then return ok, chunk end
    if not chunk then return chunk, err end
    coreg:sandbox(chunk)
    return chunk
  end
  
  --Return an iterator for file content
  function fs.lines(path)
    Verify(path,"string","Path")
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if not love.filesystem.exists(RootDir..path) then return error("File doesn't exists.") end
    if love.filesystem.isDirectory(RootDir..path) then return error("Can't read content of a directory.") end
    
    return love.filesystem.lines(RootDir..path)
  end
  
  --Write a file
  function fs.write(path,data,size)
    Verify(path,"string","Path")
    Verify(data,"string","Data")
    if size then Verify(size,"number","Size") end
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if love.filesystem.isDirectory(RootDir..path) then return error("Can't write on a directory.") end
    
    local fsize = size or data:len()
    
    if love.filesystem.exists(RootDir..path) then
      fsize = fsize - love.filesystem.getSize(RootDir..path)
    end
    
    if Drives[drive].Usage + fsize > Drives[drive].Size then error("No enough space.") end
    
    createPath(fs.getDirectory(path))
    love.filesystem.write(RootDir..path,data,size)
    
    Drives[drive].Usage = Drives[drive].Usage + fsize
  end
  
  --Append data to a file
  function fs.append(path,data,size)
    Verify(path,"string","Path")
    Verify(data,"string","Data")
    if size then Verify(size,"string","Size") end
    
    local path, drive = sanitizePath(path); path = drive.."/"..path
    
    if love.filesystem.isDirectory(RootDir..path) then return error("Can't append data on a directory.") end
    
    local asize = size or data:len()
    if Drives[drive].Usage + asize > Drives[drive].Size then error("No enough space.") end
    
    createPath(fs.getDirectory(path))
    
    if love.filesystem.exists(RootDir..path) then
      love.filesystem.append(RootDir..path,data,size)
    else
      love.filesystem.write(RootDir..path,data,size)
    end
    
    Drives[drive].Usage = Drives[drive].Usage + asize
  end
  
  function devkit.calcUsage()
    for k, v in pairs(Drives) do
      v.Usage = getSizeRecursive(k)
    end
  end
  
  return fs, yfs, devkit
end