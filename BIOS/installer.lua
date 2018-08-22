--The OS Installer

local devmode = (love.filesystem.getInfo("/Miscellaneous/devmode.txt") and true or false) or (_LVer.tag == "DEV")

local HandledAPIS, osName, update, osDrive = ...

osDrive = osDrive or "C"

local Title
if update then
  Title = "=--------< Updating "..osName.." >--------="
else
  Title = "=-------< Installing "..osName.." >-------="
  devmode = false
end

local GPU = HandledAPIS.GPU
local fs = HandledAPIS.HDD

local sw,sh = GPU.screenSize()
local fh = GPU.fontHeight()

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
  GPU.screenshot(0,9+fh+1,sw,sh-9-fh-3-9):image():draw(0,9)
  --Clear the last line
  GPU.rect(0,sh-8-fh-4,sw,fh+1,false,5)
  --Display the new message
  GPU.color(6) GPU.print(tostring(text),1,sh-9-fh-3)
  --Make sure that it's shown to the user
  GPU.flip()
end

if update and false then --Temporary disable this thing.
  display("Indexing Files")
  
  local function index(path, list)
    path = path or "/OS/DiskOS/"
    list = list or {}

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
    local HDDPath = osDrive..":/"..path:sub(OSPathLen+1,-1)
    if fs.exists(HDDPath) then
      local info = love.filesystem.getInfo(path,"file")
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
  
  local removeBoot = false
  
  local function index(path, list, sub)
    path = path or "/OS/DiskOS/"
    list = list or {}

    local items = love.filesystem.getDirectoryItems(path)
    for id, item in ipairs(items) do
      if love.filesystem.getInfo(path..item,"directory") then
        table.insert(list,path..item)
        index(path..item.."/", list, true)
      else
        if item == "boot.lua" and sub then removeBoot = true end
        table.insert(list,path..item)
      end
    end

    return list
  end
  
  local OSPath = "/OS/"..osName.."/"
  local OSPathLen = OSPath:len()
  
  local OSFiles = index("/OS/"..osName.."/")
  local hasBoot = false
  drawProgress(0)
  
  if fs.exists(osDrive..":/boot.lua") and removeBoot then
    fs.delete(osDrive..":/boot.lua")
  end
  
  for k, path in ipairs(OSFiles) do
    local HDDPath = osDrive..":/"..path:sub(OSPathLen+1,-1)
    if love.filesystem.getInfo(path,"directory") then
      fs.newDirectory(HDDPath)
      display("Directory: "..HDDPath)
    elseif HDDPath ~= osDrive..":/boot.lua" then
      local data = love.filesystem.read(path)
      fs.write(HDDPath,data)
      display("File: "..HDDPath)
    else
      hasBoot = {path,HDDPath}
    end
    drawProgress(math.max(k-1,0)/#OSFiles)
  end
  
  if hasBoot then
    local data = love.filesystem.read(hasBoot[1])
    fs.write(hasBoot[2],data)
    display("File: "..hasBoot[2])
    
    drawProgress(1)
  end
  
  if osName ~= "DiskOS" then
    fs.write(osDrive..":/.noupdate","This file ensures that the operating system is not overwritten by DiskOS when LIKO-12's version is changed.")
  end
end

GPU.clear(0)