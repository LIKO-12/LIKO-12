--BIOS Setup Screen

--luacheck: push ignore 211
local Handled, Devkits = ... --Handled is passed by BIOS POST
--luacheck: pop

--Engine parts
local coreg = require("Engine.coreg")

--Peripherals
local BIOS = Handled.BIOS
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD
local TC = Handled.TC

--Constants
local sw,sh = GPU.screenSize()
local fw,fh = GPU.fontSize()

local checkboard = GPU.imagedata("LK12;GPUIMG;2x2;7007")

local TMap = {"left","right","up","down","z","x","c"}

--Setup Variables
local events = {}
local options = {} --Will be overrided later.
local selectedOption = 1

--Functions
local function eventLoop(evlist)
  for event, a,b,c,d,e,f in CPU.pullEvent do
    
    if evlist[event] then
      if evlist[event](a,b,c,d,e,f) then break end
    end
    
  end
end

local function printBG(text,x,y,tc,bc)
  local bgw, bgh = #text*(fw+1)+1, fh+1
  GPU.rect(x-1,y-1,bgw,bgh,false,bc)
  GPU.color(tc)
  GPU.print(text,x,y)
end

local function printCenterBG(text,y,tc,bc)
  local txtw = #text*(fw+1)-1
  printBG(text,(sw-txtw)/2,y,tc,bc)
end

local function drawUI()
  GPU.clear(5) --Dark Gray
  
  --Top & Bottom Bar
  GPU.rect(0,0,sw,8,false,12)
  GPU.rect(0,sh-8,sw,8,false,12)
  
  GPU.patternFill(checkboard)
  GPU.rect(1,1,sw-2,6,false,1)
  GPU.rect(1,sh-7,sw-2,6,false,1)
  GPU.patternFill()
  
  printCenterBG("@=- BIOS SETUP V2.0 -=@",1,1,12)
  
  --Options
  for id, option in ipairs(options) do
    local txty = 14+(id-1)*(fh+2)
    
    local selected = (id == selectedOption)
    
    --Selection Rect
    GPU.rect(1,txty-1,sw-2,fh+1,false, selected and 6 or 5)
    
    GPU.color(selected and 7 or 6)
    GPU.print(option[1],2,txty)
  end
end

--Touch to Keyboard
function events.touchcontrol(down,tid)
  CPU.triggerEvent(down and "keypressed" or "keyreleased",TMap[tid],TMap[tid],false)
end

--Keyboard Navigation
function events.keypressed(key,scancode,isrepeat)
  if key == "up" then
    if selectedOption == 1 then selectedOption = #options+1 end
    
    selectedOption = selectedOption - 1
    if options[selectedOption][1] == "" then
      selectedOption = selectedOption - 1
    end
    
    drawUI()
  elseif key == "down" then
    if selectedOption == #options then selectedOption = 0 end
    
    selectedOption = selectedOption + 1
    if options[selectedOption][1] == "" then
      selectedOption = selectedOption + 1
    end
    
    drawUI()
  elseif key == "z" or key == "return" then
    if isrepeat then return end
    return options[selectedOption][2]()
  end
end

local function showAppdata()
  local ev = {}
  ev.touchcontrol = events.touchcontrol
  
  local function draw()
    GPU.clear(5) --Dark Gray
    
    --Top & Bottom Bar
    GPU.rect(0,0,sw,8,false,12)
    GPU.rect(0,sh-8,sw,8,false,12)
    
    GPU.patternFill(checkboard)
    GPU.rect(1,1,sw-2,6,false,1)
    GPU.rect(1,sh-7,sw-2,6,false,1)
    GPU.patternFill()
    
    printCenterBG("@=- APPData Path -=@",1,1,12)
    
    --Appdata path
    GPU.color(7)
    GPU.print(CPU.getSaveDirectory().."/",0,sh*0.45-(fh-1)/2,sw,"center")
    
    printCenterBG("Press the green button to return back",sh*0.66,6,5)
  end
  
  function ev.keypressed(key,scancode,isrepeat)
    if key == "z" then
      return true
    end
  end
  
  draw()
  eventLoop(ev)
  drawUI()
end

local function showGPUInfo()
  local ev = {}
  local name,ver,ven,dev = love.graphics.getRendererInfo()
  local encoded = string.format("Renderer Name: %s\n\nVersion: %s\n\nVendor: %s\n\nDevice: %s",name,ver,ven,dev)
  ev.touchcontrol = events.touchcontrol
  
  local function draw()
    GPU.clear(5) --Dark Gray
    
    --Top & Bottom Bar
    GPU.rect(0,0,sw,8,false,12)
    GPU.rect(0,sh-8,sw,8,false,12)
    
    GPU.patternFill(checkboard)
    GPU.rect(1,1,sw-2,6,false,1)
    GPU.rect(1,sh-7,sw-2,6,false,1)
    GPU.patternFill()
    
    printCenterBG("@=- GPU Information -=@",1,1,12)
    
    --Appdata path
    GPU.color(7)
    GPU.print(encoded,0,sh*0.26-(fh-1)/2,sw,"center")
    if CPU.isMobile() then
      printCenterBG("Press the green button to go back",sh*0.75,6,5)
    else
      printCenterBG("Press Z to go back",sh*0.75,6,5)
    end
  end
  
  function ev.keypressed(key,scancode,isrepeat)
    if key == "z" then
      return true
    end
  end
  
  draw()
  eventLoop(ev)
  drawUI()
end

--BIOS Options
options = {
  {"- Boot from drive D", function()
    if not fs.exists("D:/boot.lua") then
      GPU._systemMessage("D:/boot.lua doesn't exist !",3,2,9)
      return
    end
    
    TC.setInput(false)
    GPU.clear(0) GPU.color(7)
    GPU.printCursor(0,0,0)
    CPU.clearEStack() --Remove any events made.
    
    fs.drive("D")
    local bootchunk, err = fs.load("/boot.lua")
    if not bootchunk then error(err or "") end --Must be replaced with an error screen.
    
    local coglob = coreg.sandbox(bootchunk)
    local co = coroutine.create(bootchunk)
    
    local HandledAPIS = BIOS.HandledAPIS()
    coroutine.yield("echo",HandledAPIS)
    coreg.setCoroutine(co,coglob) --Switch to boot.lua coroutine
    
    return true
  end},
  
  {"- Boot PoorOS", function()
    TC.setInput(false)
    GPU.clear(0) GPU.color(7)
    GPU.printCursor(0,0,0)
    CPU.clearEStack() --Remove any events made.
    
    fs.drive("C")
    local bootchunk, err = love.filesystem.load("/OS/PoorOS/boot.lua")
    if not bootchunk then error(err or "") end --Must be replaced with an error screen.
    
    local coglob = coreg.sandbox(bootchunk)
    local co = coroutine.create(bootchunk)
    
    local HandledAPIS = BIOS.HandledAPIS()
    coroutine.yield("echo",HandledAPIS)
    coreg.setCoroutine(co,coglob) --Switch to boot.lua coroutine
    
    return true
  end},
  
  {"- Show GPU Information",function()
    showGPUInfo()
  end},
  
  {"- Open Appdata Folder", function()
    if CPU.isMobile() then
      showAppdata()
    else
      CPU.openAppData("/")
    end
  end},
  
  {"- Toggle DEVMODE", function()
    if love.filesystem.getInfo("Miscellaneous/devmode.txt","file") then
      love.filesystem.remove("Miscellaneous/devmode.txt")
      GPU._systemMessage("Disabled DEVMODE",1,1,12)
    else
      love.filesystem.write("Miscellaneous/devmode.txt","")
      GPU._systemMessage("Enabled DEVMODE",1,1,12)
    end
  end},
  
  {"",function() end}, --Separetor
  
  {"- Install DiskOS", function()
    love.filesystem.load("BIOS/installer.lua")(Handled,"DiskOS",false)
    drawUI()
    GPU._systemMessage("Installed Successfully",1,1,12)
  end},
  
  {"- Install PoorOS", function()
    love.filesystem.load("BIOS/installer.lua")(Handled,"PoorOS",false)
    drawUI()
    GPU._systemMessage("Installed Successfully",1,1,12)
  end},
  
  {"",function() end}, --Separetor
  
  {"- Wipe Drive C", function()
    GPU._systemMessage("Wiping Drive C...",100)
    GPU.flip()
    fs.delete("C:/")
    GPU._systemMessage("Wiping Complete",1,1,12)
    GPU.flip()
  end},
  
  {"- Wipe Drive D", function()
    GPU._systemMessage("Wiping Drive D...",100)
    GPU.flip()
    fs.delete("D:/")
    GPU._systemMessage("Wiping Complete",1,1,12)
    GPU.flip()
  end},
  
  {"",function() end}, --Separetor
  
  {"- Reboot", function()
    CPU.reboot()
  end}
}

if CPU.isMobile() then
  options[4][1] = "- Show Appdata Folder"
end

--Enter the UI
drawUI()
TC.setInput(true)
eventLoop(events)
