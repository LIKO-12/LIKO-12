local term = require("terminal")
local eapi = require("Editors")
local json = require("Libraries.JSON")

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

for i=1,#targets do targets[targets[i]] = true end --Values to Keys, easier for searching.

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

local function log(...)
  local txt = table.concat({...}," ")
  color(txt:sub(1,2) == "- " and 7 or 6)
  print(txt) flip()
end

local function stage(...)
  color(12) print("\n"..table.concat({...}," ")..":\n")
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
local gameLK12 = LK12Utils.encodeDiskGame(eapi:export())
likosrc.OS.GameDiskOS["game.lk12"] = gameLK12
log("generated successfully")

log("- Generating build.json")
local buildJSON = json:encode_pretty({
  Title = windowTitle,
  Appdata = appdataName
})
likosrc["build.json"] = buildJSON
log("generated successfully")

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
log("done")

local buildDir = term.resolve("./"..os.date("%y%m%d_%H%M",os.time())).."/"
local baseName = gameName.." - "
local basePath = buildDir..baseName

fs.newDirectory(buildDir)

if targets.love then
  stage("Writing Universal .love file")
  fs.write(basePath.."Universal.love", gameLove)
  log("- Wrote "..baseName.."Universal.love successfully.")
end