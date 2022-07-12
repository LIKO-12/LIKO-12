--This is a fake terminal used by GameDiskOS (fused game mode).
local fw, fh = fontSize()

local versionTag = _LIKO_Version

if _LIKO_BuildType == 'development' then
  versionTag = versionTag:sub(1,7)
elseif _LIKO_BuildType == 'experimental' then
  versionTag = versionTag:sub(14,-1)
end

local buildTypeColor = ({
  ['release'] = 11,
  ['pre-release'] = 10,
  ['experimental'] = 9,
  ['development'] = 8,
  ['custom'] = 14,
})[_LIKO_BuildType]

local buildTypeSymbol = ({
  ['release'] = 'REL-',
  ['pre-release'] = 'PRE-',
  ['experimental'] = 'EXP-',
  ['development'] = 'DEV-',
  ['custom'] = versionTag == '' and 'CUSTOM' or 'CUS-',
})[_LIKO_BuildType]

clear()

SpriteGroup(25,3,4,5,1,1,1,0,_SystemSheet)
color(buildTypeColor) print(buildTypeSymbol, 44, 5, false, false)
color(6) print(versionTag, 63, 5, false, false)
color(7) print("https://liko-12.github.io/", 4, 12)

printCursor(0,2,0)

flip() sleep(0.0625)

local function crashLoop()
  color(8) print("\nPress escape/back to exit.")
  for event, key in pullEvent do
    if event == "keypressed" then
      if key == "escape" then CPU.shutdown() end
    elseif event == "touchpressed" then
      textinput(true)
    end
  end
end

sleep(0.15) print("\nBooting Game...") sleep(0.2)

if not fs.exists("game.lk12") then
  color(8) print("\ngame.lk12 doesn't exist !")
  crashLoop()
end

local lk12Data = fs.read("game.lk12")

local edata, binary, apiver = LK12Utils.decodeDiskGame(lk12Data)

if not edata then
  color(8) print("\nFailed to decode game.lk12: "..tostring(binary))
  crashLoop()
end

if binary then
  color(8) print("\nBinary game.lk12 is not supported !")
  crashLoop()
end

local Runtime = require("Runtime")

while true do
  local glob, co, chunk = Runtime.loadGame(edata, apiver)

  if not glob then
    color(8) print("\nFailed to load game.lk12: "..tostring(co))
    crashLoop()
  end

  local ok, err = Runtime.runGame(glob, co)

  if not ok then
    color(8)
    print("Game crashed !")
    print("")
    print("Please contact the game developer with the following error message given:\n")
    print(err)
    crashLoop()
  end

  printCursor(0,0,0) color(7) clear(0)
  print("Restarting Game...")
  sleep(1)
end
