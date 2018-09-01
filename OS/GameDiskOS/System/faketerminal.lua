--This is a fake terminal used by GameDiskOS (fused game mode).
local _LIKO_TAG = _LVer.tag
local _LIKO_DEV = (_LIKO_TAG == "Development")
local _LIKO_PRE = (_LIKO_TAG == "Pre-Release")
local _LIKO_BUILD = _LVer.major ..".".. _LVer.minor ..".".. _LVer.patch

local fw, fh = fontSize()

clear()
SpriteGroup(25,1,1,5,1,1,1,0,_SystemSheet)
printCursor(0,1,0)
color(_LIKO_DEV and 8 or (_LIKO_PRE and 9 or 11)) print(_LIKO_TAG,5*8+1,3)
flip() sleep(0.125)
color(7) print("V".._LIKO_BUILD,(_LIKO_DEV or _LIKO_PRE) and 53 or 43,10)
cam("translate",0,3) color(12) print("D",false) color(6) print("isk",false) color(12) print("OS") color(6) cam()
_SystemSheet:draw(60,(fw+1)*6+1,fh+3) flip() sleep(0.125)
color(6) print("\nhttp://github.com/ramilego4game/liko12")

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