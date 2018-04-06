--The OS Installer

local devmode = (love.filesystem.getInfo("/devmode.txt") and true or false) or (_LVer.tag == "DEV")

local HandledAPIS, osName, update = ...

local Title = ""
if update then
  Title = "=--------< Updating "..osName.." >--------="
else
  Title = "=-------< Installing "..osName.." >-------="
  devmode = false
end

local GPU = HandledAPIS.GPU
local CPU = HandledAPIS.CPU
local fs = HandledAPIS.HDD

local sw,sh = GPU.screenSize()
local tw,th = GPU.termSize()
local fw,fh = GPU.fontSize()

--Draws the progress bar, takes a value between 0 and 1, nil for no progress bar.
local function drawProgress(float)
  if devmode then return end
  
  GPU.rect(0,sh-9, sw,9, false, 7) --Draw the bar
  
  if not float then return end --If no progress value then we are done.
  
  --The progress bar "=" chars
  local progChars = math.floor(float*32+0.5)
  local progStr = string.rep("=", progChars)..string.rep(" ", 32-progChars)
  
  --The % percentage.
  local precent = tostring(math.floor(float*100+0.5))
  precent = string.rep(" ",3-precent:len())..precent
  
  --Draw the text.
  GPU.color(0) GPU.print("["..progStr.."]"..precent.."%",1, sh-7)
end

if not devmode then
  --Draw the GUI
  GPU.clear(5) --Clear the screen
  GPU.rect(0,0,sw,9, false, 7) --The top bar
  GPU.color(0) GPU.print(Title, 1,2, sw, "center") --Draw the title.
  drawProgress(1) --Draw the bottom bar.
end

--Display a log message
local function display(text)
  if devmode then return end
  
  --Push the text up
  GPU.screenshot(0,9+fh+2,sw,sh-9-fh-2-9):image():draw(0,9)
  --Clear the last line
  GPU.rect(0,sh-8-fh-3,sw,fh+2,false,5)
  --Display the new message
  GPU.color(6) GPU.print(tostring(text),1,sh-9-fh-2)
  --Make sure that it's shown to the user
  GPU.flip()
end

if update then
  display("Indexing Files")
  
  local function index(path, list)
    local path = path or "/OS/DiskOS/"
    local list = list or {}

    local items = love.filesystem.getDirectoryItems(path)
    for id, item in ipairs(items) do
      if love.filesystem.getInfo(path..item,"directory") then
        table.insert(list,path..item)
        index(path..item.."/", list)
      else
        table.insert(list,path..item)
      end
    end

    return list
  end
  
  local OSPath = "/OS/"..osName.."/"
  local OSPathLen = OSPath:len()
  
  local OSFiles = index("/OS/"..osName.."/")
  drawProgress(0)
  display("Updating Files...")
  
  for k, path in ipairs(OSFiles) do
    local HDDPath = "C:/"..path:sub(OSPathLen+1,-1)
    if fs.exists(HDDPath) then
      local info = love.filesystem.getInfo(path)
      if info then
        local newDate = assert(info.modtime,"failed to get mod time")
        local oldDate = assert(fs.getLastModified(HDDPath))
        if newDate > oldDate then
          local data = love.filesystem.read(path)
          fs.write(HDDPath,data)
          display("Updated File: "..HDDPath)
        end
      end
    else --New File/Directory
      if love.filesystem.getInfo(path,"directory") then
        fs.newDirectory(HDDPath)
        display("New Directory: "..HDDPath)
      else
        local data = love.filesystem.read(path)
        fs.write(HDDPath,data)
        display("New File: "..HDDPath)
      end
    end
    drawProgress(k/#OSFiles)
  end
else ---INSTALL--------------------------------------------
  display("Indexing Files")
  
  local function index(path, list)
    local path = path or "/OS/DiskOS/"
    local list = list or {}

    local items = love.filesystem.getDirectoryItems(path)
    for id, item in ipairs(items) do
      if love.filesystem.getInfo(path..item,"directory") then
        table.insert(list,path..item)
        index(path..item.."/", list)
      else
        table.insert(list,path..item)
      end
    end

    return list
  end
  
  local OSPath = "/OS/"..osName.."/"
  local OSPathLen = OSPath:len()
  
  local OSFiles = index("/OS/"..osName.."/")
  drawProgress(0)
  
  for k, path in ipairs(OSFiles) do
    local HDDPath = "C:/"..path:sub(OSPathLen+1,-1)
    if love.filesystem.getInfo(path,"directory") then
      fs.newDirectory(HDDPath)
      display("Directory: "..HDDPath)
    else
      local data = love.filesystem.read(path)
      fs.write(HDDPath,data)
      display("File: "..HDDPath)
    end
    drawProgress(k/#OSFiles)
  end
end

GPU.clear(0)