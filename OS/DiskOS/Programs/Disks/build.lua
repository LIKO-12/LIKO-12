local term = require("terminal")
local eapi = require("Editors")
local json = require("Libraries.JSON")
local lume = require("Libraries.lume")

if (...) and (...) == "-?" then
  printUsage(
    "build","Build for all targets.",
    "build [targets]","Build for specific targets.",
    "build love","Build unversal .love file.",
    "build win","Build for windows 32-bit.",
    "build linux","Build for linux.",
    "build osx","Build for apple osx."
    )
  return
end

local targets = {...}
if #targets == 0 then targets = {"love","win","linux","osx"} end
--if #targets == 0 then targets = {"love","win","linux"} end

for i=1,#targets do targets[targets[i]] = true end --Values to Keys, easier for searching.

local BuildTemplates

if targets.win or targets.linux or targets.osx then
  if not fs.exists("C:/BuildTemplates.zip") then
    color(7) print("Please download ",false)
    color(6) print("BuildTemplates.zip ",false)
    color(7) print("from ",false)
    color(6) print("https://github.com/LIKO-12/Nightly/releases")
    color(7) print("\nThen drop them into the window here")
    color(6) print("\nPress any key to open the webpage, or press escape to terminate the build")
    color(7)

    for event, a,b,c,d,e,f in pullEvent do
      if event == "keypressed" then
        if a == "escape" then
          return 1, "Build terminated."
        else
          openURL("https://github.com/LIKO-12/Nightly/releases")
        end
      elseif event == "filedropped" then
        if not b then return 1, "Failed to read file." end
        if not fs.mountZIP(b) then return 1, "Corrupted .zip file." end
        if not fs.exists("ZIP:/Linux_x86_64") then return 1, "Invalid .zip file." end
        if not fs.exists("ZIP:/OS_X") then return 1, "Invalid .zip file." end
        if not fs.exists("ZIP:/Windows_x86") then return 1, "Invalid .zip file." end
        if not fs.exists("ZIP:/Meta.json") then return 1, "Invalid .zip file." end
        fs.mountZIP()
        fs.write("C:/BuildTemplates.zip",b)
        BuildTemplates = b
        color(11) print("BuildsTemplates has been installed.")
        break
      elseif event == "touchpressed" then
        textinput(true)
      end
    end
  else
    BuildTemplates = fs.read("C:/BuildTemplates.zip")
  end
end

local function ask(name,preinput)
  --if true then return "test" end
  color(6) print(name..": ",false) color(7)
  local respond = ""
  
  while true do
    respond = TextUtils.textInput(false,preinput)
    
    if not respond then print("") return end
    if #respond > 0 then break end
    
    _systemMessage("Please supply in the "..name:lower())
  end
  
  print("")
  
  return respond
end

local gameName = ask("Game name")
if not gameName then return 1, "Build terminated." end

local authorName = ask("Author")
if not authorName then return 1, "Build terminated." end

local windowTitle = ask("Window title","LIKO-12 - "..gameName)
if not windowTitle then return 1, "Build terminated." end

local appdataName = ask("Appdata name","liko12_"..authorName:lower():gsub(" ","_").."_"..gameName:lower():gsub(" ","_"))
if not appdataName then return 1, "Build terminated." end

local packageName
if targets.osx then
  packageName = ask("Package name","com."..authorName:lower():gsub(" ","_").."."..gameName:lower():gsub(" ","_"))
  if not packageName then return 1, "Build terminated." end
end

local startTime = os.clock()

local function log(...)
  local txt = table.concat({...}," ")
  color(txt:sub(1,2) == "- " and 7 or 6)
  print(txt) flip()
end

local function stage(...)
  color(12) print("\n"..table.concat({...}," ")..":\n")
end

stage("Generating the game icon")

local iconImages = {} --16,32,48 (windows),64,128,256
local transparentColor = false --Opaque

do
  local colsL,colsR = eapi.leditors[eapi.editors.sprite]:getSelectedColors()
  if colsR == 0 then transparentColor = colsL end
  
  local selectedSprite = eapi.leditors[eapi.editors.sprite]:getSelectedSprite()
  
  if selectedSprite:width() == 8 then
    selectedSprite = selectedSprite:enlarge(2)
    log("scaled up 8x8 to 16x16")
  end
  
  
  if selectedSprite:width() == 32 then
    iconImages[1] = imagedata(16,16)
    iconImages[1]:map(function(x,y)
      return selectedSprite:getPixel(x*2,y*2)
    end)
    log("scaled down 32x32 to 16x16")
    log("made 16x16 icon")
  end
  
  if selectedSprite:width() == 16 then
    iconImages[1] = selectedSprite --16x16
    log("made 16x16 icon")
    selectedSprite = selectedSprite:enlarge(2)
  end
  
  if targets.win or targets.osx then
    iconImages[2] = selectedSprite --32x32
    log("made 32x32 icon")
    
    if targets.win then
      local icon48 = imagedata(48,48)
      if transparentColor and transparentColor ~= 0 then icon48:map(function() return transparentColor end) end
      icon48:paste(selectedSprite,8,8)
      log("placed 32x32 in 48x48 without scaling")
      iconImages[3] = icon48
      log("made 48x48 icon")
    end
    
    selectedSprite = selectedSprite:enlarge(2)
    iconImages[4] = selectedSprite
    log("made 64x64 icon")
    
    selectedSprite = selectedSprite:enlarge(2)
    iconImages[5] = selectedSprite
    log("made 128x128 icon")
    
    selectedSprite = selectedSprite:enlarge(2)
    iconImages[6] = selectedSprite
    log("made 256x256 icon")
  end
end

stage("Creating .love file")

log("- Mounting LIKO-12 Sourcecode")
local mountedSRC = BuildUtils.mountSRC()
if mountedSRC then
  log("mounted successfully")
else
  return 1,"Failed to mount LIKO-12 Sourcecode"
end

log("- Reading LIKO-12 Sourcecode")
local likosrc = BuildUtils.filesTree("ZIP:/")
log("read successfully")

log("- Unmounting LIKO-12 Sourcecode")
fs.mountZIP()
log("unmounted successfully")

log("- Generating game.lk12")
local gameLK12 = LK12Utils.encodeDiskGame(eapi:export(),false,false,eapi.apiVersion)
likosrc.OS.GameDiskOS["game.lk12"] = gameLK12
log("generated successfully")

log("- Generating build.json")
local buildJSON = json:encode_pretty({
  Title = windowTitle,
  Appdata = appdataName
})
likosrc["build.json"] = buildJSON
log("generated successfully")

log("- Replacing icon.png")
if transparentColor then
  palt(0,false) palt(transparentColor,true)
  likosrc["icon.png"] = iconImages[1]:export()
  palt()
else
  likosrc["icon.png"] = iconImages[1]:exportOpaque()
end
log("replaced successfully")

log("- Removing useless files")
likosrc.Peripherals.WEB = nil
log("removed /Peripherals/WEB")
likosrc.Engine["luajit-request"] = nil
log("removed /Engine/luajit-request")
likosrc.OS.DiskOS = nil
log("removed /OS/DiskOS")
likosrc.OS.PoorOS = nil
log("removed /OS/PoorOS")

log("- Packing .love file")
local gameLove = BuildUtils.packZIP(likosrc)
log("packed successfully")

local buildDir = term.resolve("./"..os.date("%y%m%d_%H%M",os.time())).."/"
local baseName = gameName.." - "
local basePath = buildDir..baseName

fs.newDirectory(buildDir)

if targets.love then
  stage("- Writing Universal .love file")
  fs.write(basePath.."Universal.love", gameLove)
  log("Wrote "..baseName.."Universal.love successfully.")
end

if targets.win or targets.linux or targets.osx then
  log("mounted BuildTemplates.zip")
  fs.mountZIP(BuildTemplates)
end

if targets.win then
  stage("Building for windows")
  
  log("- Reading windows template")
  local winTree = BuildUtils.filesTree("ZIP:/Windows_x86/")
  log("read successfully")
  
  log("- Patching Icon")
  local winIco = BuildUtils.encodeIco(iconImages,transparentColor)
  log("encoded windows icon")
  winTree["love.exe"] = BuildUtils.patchExeIco(winTree["love.exe"],winIco)
  log("patched love.exe icon")
  
  log("- Creating "..gameName..".exe")
  winTree[gameName..".exe"] = winTree["love.exe"] .. gameLove
  log("created "..gameName..".exe")
  
  log("- Removing useless files")
  winTree["love.ico"] = nil
  log("removed love.ico")
  winTree["game.ico"] = nil
  log("removed game.ico")
  winTree["love.exe"] = nil
  log("removed love.exe")
  winTree["lovec.exe"] = nil
  log("removed lovec.exe")
  
  log("- Removing WEB native libs")
  winTree["libcurl.dll"] = nil
  log("removed libcurl.dll")
  winTree["libeay32.dll"] = nil
  log("removed libeay32.dll")
  winTree["ssl.dll"] = nil
  log("removed ssl.dll")
  winTree["ssl.dylib"] = nil
  log("removed ssl.dylib")
  winTree["ssleay32.dll"] = nil
  log("removed ssleay32.dll")
  winTree["lua/ssl.lua"] = nil
  log("removed ssl.lua")
  
  log("- Packing windows build")
  local winZip = BuildUtils.packZIP(winTree)
  log("packed successfully")
  
  log("- Writing windows .zip file")
  fs.write(basePath.."Windows.zip", winZip)
  log("Wrote "..baseName.."Windows.zip successfully.")
end

if targets.linux then
  stage("Building for linux")
  
  log("- Reading linux template")
  local linuxTree = BuildUtils.filesTree("ZIP:/Linux_x86_64/")
  log("read successfully")
  
  log("- Adding game files")
  for k,v in pairs(likosrc) do
    linuxTree[k] = v
  end
  log("added successfully")
  
  log("- Packing linux build")
  local linuxZip = BuildUtils.packZIP(linuxTree)
  log("packed successfully")
  
  log("- Writing linux .zip file")
  fs.write(basePath.."Linux.zip", linuxZip)
  log("Wrote "..baseName.."Linux.zip successfully.")
end

if targets.osx then
  stage("Building for OSX")
  
  log("- Reading osx template")
  local osxTree = BuildUtils.filesTree("ZIP:/OS_X")
  log("read successfully")
  
  log("- Adding "..gameName..".love")
  osxTree["LIKO-12.app"].Contents.Resources[gameName..".love"] = gameLove
  log("added successfully")
  
  log("- Patching Info.plist")
  osxTree["LIKO-12.app"].Contents["Info.plist"] = osxTree["LIKO-12.app"].Contents["Info.plist"]:gsub("LIKO%-12",gameName):gsub("me.ramilego4game.liko12",packageName)
  log("patched successfully")
  
  log("- Renaming LIKO-12.app")
  osxTree[gameName..".app"] = osxTree["LIKO-12.app"]
  osxTree["LIKO-12.app"] = nil
  log("renamed to "..gameName..".app successfully.")
  
  log("- Packing osx build")
  local osxZip = BuildUtils.packZIP(osxTree)
  log("packed successfully")
  
  log("- Writing osx .zip file")
  fs.write(basePath.."OSX.zip", osxZip)
  log("Wrote "..baseName.."OSX.zip successfully.")
end

if targets.win or targets.linux or targets.osx then
  fs.mountZIP()
  log("unmounted BuildTemplates.zip")
end

local endTime = os.clock()

color(11) print("\nBuilt successfully in "..math.floor(endTime - startTime).."s")
