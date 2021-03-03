--BIOS Setup Screen

--luacheck: push ignore 211
local Handled, Devkits = ... --Handled is passed by BIOS POST
--luacheck: pop

local DevMode = love.filesystem.getInfo("/Miscellaneous/devmode.txt") and true or false

--Peripherals
local Keyboard = Handled.Keyboard
local GPU = Handled.GPU
local CPU = Handled.CPU
local fs = Handled.HDD
local TC = Handled.TC

--Constants
local sw,sh = GPU.screenSize()
local tw = GPU.termWidth()
local fw,fh = GPU.fontSize()
local mobile = CPU.isMobile()

local checkboard = GPU.imagedata("LK12;GPUIMG;2x2;7007")

--Setup Variables
local selectedTab = 1
local tabs = {}
local tools = {}

--Touch to Keyboard
local TMap = {"left","right","up","down","return","escape","backspace"}
local function touchToKeyboard(down,tid)
  CPU.triggerEvent(down and "keypressed" or "keyreleased",TMap[tid],TMap[tid],false)
end

--The event loop
local function eventLoop(evlist)
  for event, a,b,c,d,e,f in CPU.pullEvent do
    if event == "touchcontrol" then
      touchToKeyboard(a,b)
    end
    
    if evlist then
      if evlist[event] then
        if evlist[event](evlist,a,b,c,d,e,f) then break end
      end
    else
      if tabs[selectedTab][2][event] then
        if tabs[selectedTab][2][event](tabs[selectedTab][2],a,b,c,d,e,f) then break end
      end
    end
  end
end

--FS Size calculation
local function storageSize(size)
  if size < 1024 then --Bytes
    return size.." B"
  elseif size < 1024^2 then --Kilo-bytes
    return (math.floor(size/102.4)/10).." KB"
  else --Mega-bytes
    return (math.floor(size/(1024^2 * 0.1))/10).." MB"
  end
end

--==Graphics==--

--Show a blue-colored system message.
local function systemMessage(msg,time,textC,bgC,hideInGif)
  GPU._systemMessage(msg,time,textC or 1, bgC or 12, hideInGif)
end

--Print with background text.
local function printBG(text,x,y,tc,bc,et)
  et = et or 0
  local bgw, bgh = #text*(fw+1)+1+et*2, fh+2
  if bc then GPU.rect(x-1-et,y-1,bgw,bgh,false,bc) end
  GPU.color(tc)
  GPU.print(text,x,y)
  return bgw
end

--Print with background centered text.
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
    printCenterBG(title,1,1,12)
  end
end

local function arrowSelected(id,selectedID)
  if id == selectedID then
    return "\xDC\x88\x88" -- <--
  else
    return ""
  end
end

--==User Interface==--

--Draw the basic UI.
local function drawUI(subMenu)
  GPU.clear(5) --Light Gray
  
  --Draw the top & bottom bars
  drawBars(subMenu or "@=- BIOS SETUP V3.0 -=@")
  
  if subMenu then
    --Draw black lines without space for the tabs bar
    GPU.line(-1,8,sw+1,8,0)
    GPU.line(-1,sh-9,sw+1,sh-9,0)
    
    return
  end
  
  --Draw the tabs body
  GPU.rect(0,8,sw,8,false,13)
  
  --Draw black lines
  GPU.line(-1,16,sw+1,16,0)
  GPU.line(-1,sh-9,sw+1,sh-9,0)
  
  --Draw the tabs
  local nextTabX = 5
  for t=1, #tabs do
    local bc = (selectedTab == t and 1)
    local tc = (selectedTab == t and 13 or 0)
    nextTabX = nextTabX + printBG(tabs[t][1],nextTabX,9, tc,bc,1) + 10
  end
end

--Handle the keypresses for the tabs, returns true when the tab is changed.
local function keypressTabs(key,sc,isrepeat)
  local oldTab = selectedTab
  if key == "left" then
    selectedTab = math.max(selectedTab-1,1)
  elseif key == "right" then
    selectedTab = math.min(selectedTab+1,#tabs)
  end
  if selectedTab ~= oldTab and tabs[selectedTab][2].selected then
    tabs[selectedTab][2].selected(tabs[selectedTab][2])
    return true
  end
end

--Draw a list of options
local function drawOptions(tree,selectedOption)
  for i=1, #tree do
    local name = tree[i][1]
    local value = tree[i][2]
    
    if name ~= "" then
      if type(value) == "function" then
        value = value(i,selectedOption)
      end
      
      local tc --The option name color.
      if selectedOption == i then
        tc, name = 7, "\xD1"..name
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

--Handle the option selection, returns the new selection id when the key is up or down.
local function keypressOptions(key,tree,selectedOption)
  if key == "up" then
    local newSel = math.max(selectedOption-1,1)
    return tree[newSel][1] == "" and newSel-1 or newSel
  elseif key == "down" then
    local newSel = math.min(selectedOption+1,#tree)
    return tree[newSel][1] == "" and newSel+1 or newSel
  end
end

--==Tabs==--

--##Information Tab##--

tabs[1] = {"Info",{
  selectedOption = 1,
  
  options = {
    {"NormBIOS:      ",string.format("Revision %d%d%d-018",_LVer.major,_LVer.minor,_LVer.patch)},
    {""}, --Spacer
    {"System Time:   ",function() return os.date("[%H:%M:%S]",os.time()) end},
    {"System Date:   ",function() return os.date("[%d/%m/%Y]",os.time()) end},
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
    {"Battery Charge:   ",function()
      local _, precent = love.system.getPowerInfo()
      if precent then
        return precent.."%"
      else
        return "-"
      end
    end},
    {"Remaining Time:   ",function()
      local _,_,time = love.system.getPowerInfo()
      if time then
        return math.floor(time/60).."m"
      else
        return "-"
      end
    end},
    {""},
    {"Host Info:     ","[Deselect]"},
  },
  
  update = function(self,dt)
    drawUI()
    
    --Host information
    if self.selectedOption == #self.options then
      drawOptions(self.hostOptions,#self.hostOptions)
    else --Info Data
      drawOptions(self.options,self.selectedOption)
    end
  end,
  
  keypressed = function(self,key,sc,isrepeat)
    if keypressTabs(key,sc,isrepeat) then return end
    
    local newSel = keypressOptions(key,self.options,self.selectedOption)
    if newSel then self.selectedOption = newSel; return end
  end
}}

local defaultEvents = {
  update=function(self,dt) drawUI() GPU.color(7) GPU.print("Comming Soon...",3,20) end,
  keypressed = function(self,...) keypressTabs(...) end
}

tabs[2] = {"Peripherals",defaultEvents}

--##Boot Tab##--

tabs[3] = {"Boot",{
  selectedOption = 1,
  
  options = {
    {"Reboot. ",arrowSelected},
  },
  
  update = function(self,dt)
    drawUI()
    
    drawOptions(self.options,self.selectedOption)
  end,
  
  keypressed = function(self,key,sc,isrepeat)
    if keypressTabs(key,sc,isrepeat) then return end
    
    local newSel = keypressOptions(key,self.options,self.selectedOption)
    if newSel then self.selectedOption = newSel; return end
    
    if key == "return" then
      if self.selectedOption == 1 then --Reboot
        CPU.reboot()
      end
    end
  end
}}

--##Tools Tab##--

tabs[4] = {"Tools",{
  selectedOption = 1,
  
  options = {
    {"Open appdata. ",arrowSelected},
    {"Show appdata path. ",arrowSelected},
    {"Wipe a drive. ",arrowSelected},
    {"OS Installer.",arrowSelected},
    {"Toggle Devmode. ",arrowSelected},
  },
  
  update = function(self,dt)
    drawUI() drawOptions(self.options,self.selectedOption)
  end,
  
  keypressed = function(self,key,sc,isrepeat)
    if keypressTabs(key,sc,isrepeat) then return end
    
    local newSel = keypressOptions(key,self.options,self.selectedOption)
    if newSel then self.selectedOption = newSel; return end
    
    if key == "return" and tools[self.selectedOption] then
      tools[self.selectedOption]()
    end
  end
}}

--==Tools==--

--Open Appdata
tools[1] = function()
  if CPU.isMobile() then
    systemMessage("Can't open AppData on Android yet.",5)
  else
    CPU.openAppData("/")
    systemMessage("Openned Successfully.")
  end
end

--Show Appdata
local appdataPath = CPU.getSaveDirectory().."/"
local showAppdataEvents = {
  update = function()
    drawUI("@=- APPData Path -=@")
    
    GPU.color(7)
    GPU.print(appdataPath,0,sh*0.45-(fh-1)/2,sw,"center")
    
    printCenterBG("Press "..(mobile and "the red button" or "escape").." to return back",sh*0.66,6,5)
  end,
  
  keypressed = function(self,key)
    return (key == "escape")
  end
}
tools[2] = function() eventLoop(showAppdataEvents) end

--Wipe a drive
local wipeADriveEvents = {
  selected = function(self)
    self.options = {}
    self.selectedOption = 1
    
    for name,info in pairs(fs.drives()) do
      local subinfo = info.ReadOnly and "[ReadOnly]" or string.format("[%s/%s]",storageSize(info.usage),storageSize(info.size))
      
      self.options[#self.options + 1] = {
        "Wipe drive ("..name..")"..string.rep(" ",tw-13-#name-#subinfo-2),
        subinfo
      }
    end
  end,
  
  update = function(self)
    drawUI("@=- Wipe a drive -=@")
    
    --Warning box
    GPU.rect(0,8,sw,8,false,2)
    GPU.line(-1,8,sw+1,8,1)
    GPU.color(8) GPU.print("\xE3!\xE2 WARNING: THIS CANNOT BE REVERTED !",1,10)
    GPU.line(-1,16,sw+1,16,0)
    
    drawOptions(self.options,self.selectedOption)
    
    printBG("\xC2 Press "..(mobile and "the red button" or "escape").." to return back",2,sh-16,0)
  end,
  
  keypressed = function(self,key,_,isrepeat)
    local newSel = keypressOptions(key,self.options,self.selectedOption)
    if newSel then self.selectedOption = newSel; return end
    
    if key == "return" and not isrepeat then
      if self.options[self.selectedOption][2] == "[ReadOnly]" then
        systemMessage("Can't wipe a readonly drive !",4)
      else
        local driveName = self.options[self.selectedOption][1]:sub(13,-1):gsub(" ",""):sub(1,-2)
        systemMessage("Wiping drive ("..driveName..")...",100)
        GPU.flip()
        fs.delete(driveName..":/")
        systemMessage("Wiped drive ("..driveName..") successfully.",2)
        GPU.flip()
      end
    elseif key == "escape" then
      return true
    end
  end
}

tools[3] = function()
  wipeADriveEvents.selected(wipeADriveEvents)
  eventLoop(wipeADriveEvents)
end

--OS Installer
local osInstallerEvents = {}
do
  local install_os = "DiskOS"
  local install_drive = "C"
  local install_wipe = true
  
  local function osOption() return install_os.." [Change]" end
  local function osDrive() return install_drive.." [Change]" end
  local function osWipe() return install_wipe and "YES [Toggle]" or "NO  [Toggle]" end
  
  local selected_main
  local options_main = {
    {"Operating System: ",osOption},
    {""},
    {"Destination Drive: ",osDrive},
    {""},
    {"Wipe drive: ",osWipe},
    {""},
    {"Start Installation ",arrowSelected}
  }
  
  local selected_os
  local options_os = {}
  for _,osname in ipairs(love.filesystem.getDirectoryItems("/OS/")) do
    if osname ~= "GameDiskOS" then options_os[#options_os+1] = {"- "..osname..". ",arrowSelected} end
  end
  
  local selected_drive
  local options_drive = {}
  local function updateDrivesList()
    options_drive = {}
    for driveName, info in pairs(fs.drives()) do
      if not info.readonly then options_drive[#options_drive + 1] = {"- Drive ("..driveName.."). ",arrowSelected} end
    end
  end
  
  function osInstallerEvents:selected()
    install_os = "DiskOS"
    install_drive = "C"
    install_wipe = true
    
    selected_main = 1
    
    updateDrivesList()
  end
  
  function osInstallerEvents:update()
    drawUI("@=- OS Installer -=@")
    
    --Warning box
    GPU.rect(0,8,sw,8,false,2)
    GPU.line(-1,8,sw+1,8,1)
    GPU.color(8) GPU.print("\xE3!\xE2 WARNING: THIS CANNOT BE REVERTED !",1,10)
    GPU.line(-1,16,sw+1,16,0)
    
    if selected_os then
      drawOptions(options_os,selected_os)
    elseif selected_drive then
      drawOptions(options_drive,selected_drive)
    else
      drawOptions(options_main,selected_main)
    end
    
    printBG("\xC3 Some operating systems won't work",2,sh-16-(fh+2)*2,0)
    printBG("  if not installed on drive C.",2,sh-16-fh-2,0)
    printBG("\xC2 Press "..(mobile and "the red button" or "escape").." to return back",2,sh-16,0)
  end
  
  function osInstallerEvents:keypressed(key,_,isrepeat)
    if selected_os then
      local newSel = keypressOptions(key,options_os,selected_os)
      if newSel then selected_os = newSel; return end
      
      if key == "return" and not isrepeat then
        install_os = options_os[selected_os][1]:sub(3,-3)
        selected_os = nil
      elseif key == "escape" then
        selected_os = nil
      end
    elseif selected_drive then
      local newSel = keypressOptions(key,options_drive,selected_drive)
      if newSel then selected_drive = newSel; return end
      
      if key == "return" and not isrepeat then
        install_drive = options_drive[selected_drive][1]:sub(10,-4)
        selected_drive = nil
      elseif key == "escape" then
        selected_drive = nil
      end
    else
      local newSel = keypressOptions(key,options_main,selected_main)
      if newSel then selected_main = newSel; return end
      
      if key == "return" and not isrepeat then
        if selected_main == 1 then --OS Selection
          selected_os = 1
        elseif selected_main == 3 then --Drive Selection
          selected_drive = 1
        elseif selected_main == 5 then --Wipe Toggle
          install_wipe = not install_wipe
        elseif selected_main == 7 then --Installation
          if install_wipe then
            systemMessage("Wiping drive ("..install_drive..")...",100)
            GPU.flip()
            fs.delete(install_drive..":/")
            systemMessage("Started Installation",0)
            GPU.flip()
          end
          
          love.filesystem.load("BIOS/installer.lua")(Handled,install_os,false,install_drive)
          systemMessage("Installed Successfully",1)
        end
      elseif key == "escape" then
        return true
      end
    end
  end
end

tools[4] = function()
  osInstallerEvents:selected()
  eventLoop(osInstallerEvents)
end

--Toggle Devmode
tools[5] = function()
  if love.filesystem.getInfo("Miscellaneous/devmode.txt","file") then
    love.filesystem.remove("Miscellaneous/devmode.txt")
    systemMessage("Disabled DEVMODE")
  else
    love.filesystem.write("Miscellaneous/devmode.txt","")
    systemMessage("Enabled DEVMODE")
  end
end

--==Execution==--

TC.setInput(true)
Keyboard.keyrepeat(true)
eventLoop()
