--BIOS Setup Screen

--luacheck: push ignore 211
local Handled, Devkits = ... --Handled is passed by BIOS POST
--luacheck: pop

local DevMode = love.filesystem.getInfo("/Misc/devmode.txt") and true or false

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
local tw,th = GPU.termSize()
local fw,fh = GPU.fontSize()

local checkboard = GPU.imagedata("LK12;GPUIMG;2x2;7007")

--Setup Variables
local selectedTab = 1
local tabs = {}

--Touch to Keyboard
local TMap = {"left","right","up","down","z","x","c"}
local function touchToKeyboard(down,tid)
  CPU.triggerEvent(down and "keypressed" or "keyreleased",TMap[tid],TMap[tid],false)
end

--Functions
local function eventLoop(evlist)
  for event, a,b,c,d,e,f in CPU.pullEvent do
    if event == "touchcontrol" then
      touchToKeyboard(a,b)
    end
    
    if evlist then
      if evlist[event] then
        if evlist[event](a,b,c,d,e,f) then break end
      end
    else
      if tabs[selectedTab][2][event] then
        if tabs[selectedTab][2][event](tabs[selectedTab][2],a,b,c,d,e,f) then break end
      end
    end
  end
end

--Graphics
local function printBG(text,x,y,tc,bc,et)
  et = et or 0
  local bgw, bgh = #text*(fw+1)+1+et*2, fh+2
  if bc then GPU.rect(x-1-et,y-1,bgw,bgh,false,bc) end
  GPU.color(tc)
  GPU.print(text,x,y)
  return bgw
end

local function printCenterBG(text,y,tc,bc)
  local txtw = #text*(fw+1)-1
  return printBG(text,(sw-txtw)/2,y,tc,bc)
end

--Draw the top & bottom bars.
local function drawBars(title)
  GPU.rect(0,0,sw,8,false,12)
  GPU.rect(0,sh-8,sw,8,false,12)
  
  GPU.patternFill(checkboard)
  GPU.rect(1,1,sw-2,6,false,1)
  GPU.rect(1,sh-7,sw-2,6,false,1)
  GPU.patternFill()
  
  if title then
    printCenterBG("@=- BIOS SETUP V3.0 -=@",1,1,12)
  end
end

local function drawUI()
  GPU.clear(5) --Light Gray
  
  --Draw the top & bottom bars
  drawBars("@=- BIOS SETUP V3.0 -=@")
  
  --Draw the tabs body
  GPU.rect(0,8,sw,8,false,13)
  
  --Draw the tabs
  local nextTabX = 5
  for t=1, #tabs do
    local bc = (selectedTab == t and 1)
    local tc = (selectedTab == t and 13 or 0)
    nextTabX = nextTabX + printBG(tabs[t][1],nextTabX,9, tc,bc,1) + 10
  end
  
  --Draw black lines
  GPU.line(-1,16,sw+1,16,0)
  GPU.line(-1,sh-9,sw+1,sh-9,0)
end

local function keypressTabs(key,sc,isrepeat)
  local oldTab = selectedTab
  if key == "left" then
    selectedTab = math.max(selectedTab-1,1)
  elseif key == "right" then
    selectedTab = math.min(selectedTab+1,#tabs)
  end
  if selectedTab ~= oldTab and tabs[selectedTab][2].init then
    tabs[selectedTab][2].init(tabs[selectedTab][2])
  end
end

local function drawOptions(tree,selectedOption)
  for i=1, #tree do
    local name = tree[i][1]
    local value = tree[i][2]
    
    if name ~= "" then
      if type(value) == "function" then
        value = value()
      end
      
      local tc --The option name color.
      if selectedOption == i then
        tc, name = 7, "\xE0"..name
      else
        tc, name = 6, " "..name
      end
      
      GPU.color(tc)
      GPU.print(name,1,20+(i-1)*(fh+4))
      
      GPU.color(0)
      GPU.print(value,1+#name*(fw+1),20+(i-1)*(fh+4))
    end
  end
end

local function keypressOptions(key,tree,selectedOption)
  if key == "up" then
    local newSel = math.max(selectedOption-1,1)
    return tree[newSel][1] == "" and newSel-1 or newSel
  elseif key == "down" then
    local newSel = math.min(selectedOption+1,#tree)
    return tree[newSel][1] == "" and newSel+1 or newSel
  end
end

tabs[1] = {"Info",{
  selectedOption = 1,
  
  options = {
    {"NormBIOS:      ",string.format("Revision %d%d%d-018",_LVer.major,_LVer.minor,_LVer.patch)},
    {""}, --Spacer
    {"System Time:   ",function() return os.date("[%H:%M:%S]",os.time()) end},
    {"System Date:   ",function() return os.date("[%d:%m:%Y]",os.time()) end},
    {""}, --Spacer
    {"LIKO-12 Ver:   ",_LVERSION:sub(2,-1)},
    {"Devmode:       ",DevMode and "Enabled" or "Disabled"},
    {"Custom OS:     ",fs.exists("C:/.noupdate") and "Yes" or "No"},
    {""}, --Spacer
    {"Host Info:     ","[Details]"},
  },
  
  hostOptions = {
    {"Operating System: ",love.system.getOS()},
    {"Processors:       ",love.system.getProcessorCount()},
    {""},
    {"GPU: ",select(4,love.graphics.getRendererInfo()).." - "..love.graphics.getRendererInfo()},
    {""},
    {"Power State:      ",function() return love.system.getPowerInfo() end},
    {"Battery Charge:   ",function() return select(2,love.system.getPowerInfo()) or "-" end},
    {"Remaining Time:   ",function() return select(3,love.system.getPowerInfo()) or "-" end},
    {""},
    {"Host Info:     ","[Deselect]"},
  },
  
  update = function(self,dt)
    drawUI()
    
    drawOptions(self.options,self.selectedOption)
    
    --Host information
    if self.selectedOption == #self.options then
      GPU.rect(0,17,sw,sh-26,false,5)
      drawOptions(self.hostOptions,#self.hostOptions)
    end
  end,
  
  keypressed = function(self,key,sc,isrepeat)
    if keypressTabs(key,sc,isrepeat) then return end
    
    local newSel = keypressOptions(key,self.options,self.selectedOption)
    if newSel then self.selectedOption = newSel; return end
  end
}}

local defaultEvents = {
  update=function(self,dt) drawUI() end,
  keypressed = function(self,...) keypressTabs(...) end
}

tabs[2] = {"Peripherals",defaultEvents}
tabs[3] = {"Boot",defaultEvents}
tabs[4] = {"Tools",defaultEvents}

eventLoop()

--[[local mainEvents = {}
mainEvents.update = drawUI

eventLoop(mainEvents)]]