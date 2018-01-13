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
  
  local fs, devkit, indirect = {}, {}, {}
  
  --Helping functions
  local function sanitizePath(path,wild)
    --Allow windowsy slashes
    path = path:gsub("\\","/")
    
    if path:sub(-2,-1) == ":/" then path = path.."/" end --(C:/)
    
    --Parse the drive name (if provided) ([driveName]:/[path])
    local drive = ActiveDrive
    local d, p = path:match("(.+):/(.+)")
    if d then
      if not Drives[d] then error("Drive '"..d.."' doesn't exists !",3) end
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
    return drive, table.concat(output,"/")
  end
  
  local function createPath(drive,path)
    local parts = split(path,"/")
    local totalPath = drive.."/"
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
  
  --FIXME findIn
  local function findIn( startDir, matches, wildPattern )
    local list = fs.directoryItems(startDir)
    for k, entry in ipairs(list) do
      local entryPath = (startDir:len() == 0) and entry or startDir.."/"..entry
      if string.match(entryPath, wildPattern) then
        table.insert(matches,entryPath)
      end
      
      if fs.isDirectory(entryPath) then
        findIn( entryPath, matches, wildPattern )
      end
    end
  end
  
  --NOTE: The from and to should include the drive folder (eg C:/ex -> c/ex)
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
  
  --NOTE: The from and to should include the drive folder (eg C:/ex -> c/ex)
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
  
  --NOTE: The from and to should include the drive folder (eg C:/ex -> c/ex)
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
  
  
  return fs, devkit, indirect
end