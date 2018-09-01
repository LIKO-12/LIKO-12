--Migrating script from LIKO-12 0.8.0 and earlier.
local HandledAPIS = ...

--Peripherals
local GPU = HandledAPIS.GPU
local CPU = HandledAPIS.CPU
local fs = HandledAPIS.HDD

--Filesystem identity
local nIdentity = love.filesystem.getIdentity()
local oIdentity = "liko12"

--Helper functions
local function msg(...)
  GPU._systemMessage(table.concat({...}),3600,0,7)
  CPU.sleep(0)
end

--Activate old identity
local function activate()
  love.filesystem.setIdentity(oIdentity)
end

--Deactivate old identity
local function deactivate()
  love.filesystem.setIdentity(nIdentity)
end

--Directories indexing function.
local function index(path,list,ext,rec)
  if not love.filesystem.getInfo(path) then return end
  
  for _,file in ipairs(love.filesystem.getDirectoryItems(path)) do
    local info = love.filesystem.getInfo(path..file)
    if info and info.type == "file" then
      if not ext or file:sub(-#ext,-1) == ext then
        list[#list + 1] = path..file
      end
    elseif info and rec then
      index(path..file.."/",list,ext,rec)
    end
  end
end

--Start migrating
msg("Migrating your old data (0%)...")

local Data = {} --The files in the D drive.
local Screenshots = {} --The .png files in the appdata folder.
local GIFs = {} --The .gif files in the appdata folder.
local Shaders = {} --The GPU shaders.

activate()
index("/",Screenshots,".png")
index("/Screenshots",Screenshots,".png",true)

index("/",GIFs,".gif")
index("/GIF Recordings/",GIFs,".gif",true)

index("/Shaders/",Shaders,false,true)
index("/drives/D/",Data,false,true)

if love.filesystem.getInfo("/drives/C/user.json") then
  Data[#Data + 1] = "/drives/C/user.json"
end

if love.filesystem.getInfo("/drives/C/_backup.lk12") then
  Data[#Data + 1] = "/drives/C/_backup.lk12"
end
deactivate()

local total = #Screenshots + #GIFs + #Shaders + #Data
local processed = 0

local function progress(skip)
  if not skip then processed = processed + 1 end
  msg("Migrating your old data (",math.floor((processed/total)*100),"%)...")
end

for i=1, #Data do
  local src = Data[i]
  local dst = "/D"..src:sub(3,-1)
  activate()
  local data = love.filesystem.read(src)
  deactivate()
  love.filesystem.createDirectory(fs.getDirectory(dst))
  love.filesystem.write(dst,data)
  progress()
end

for i=1, #Shaders do
  local path = Shaders[i]
  activate()
  local data = love.filesystem.read(path)
  deactivate()
  love.filesystem.createDirectory(fs.getDirectory(path))
  love.filesystem.write(path,data)
  progress()
end

for i=1, #GIFs do
  local src = GIFs[i]
  local dst = src:sub(1,16) == "/GIF Recordings/" and src or "/GIF Recordings"..src
  activate()
  local data = love.filesystem.read(src)
  deactivate()
  love.filesystem.createDirectory(fs.getDirectory(dst))
  love.filesystem.write(dst,data)
  progress()
end

for i=1, #Screenshots do
  local src = Screenshots[i]
  if src ~= "/icon.png" then
    local dst = src:sub(1,13) == "/Screenshots/" and src or "/Screenshots"..src
    activate()
    local data = love.filesystem.read(src)
    deactivate()
    love.filesystem.createDirectory(fs.getDirectory(dst))
    love.filesystem.write(dst,data)
    progress()
  end
end

activate()
if love.filesystem.getInfo(".version") then
  love.filesystem.remove(".version")
end

if love.filesystem.getInfo("Miscellaneous/.version") then
  love.filesystem.remove("Miscellaneous/.version")
end
deactivate()

GPU._systemMessage("",0)