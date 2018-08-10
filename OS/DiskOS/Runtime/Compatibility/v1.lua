--Compatibility layer for the old API v1.

--The game globals table, and the game coroutine.
local glob, co = ...

--Set the values that were available in System/api.lua
--They are set as their old values.

glob._DiskVer = 4
glob._MinDiskVer = 2

--Restore the legacy input function:
function glob.input()
  local t = ""
  
  local fw, fh = fontSize()
  local blink = false
  local blinktimer = 0
  local blinktime = 0.5
  local function drawblink()
    local cx,cy,c = printCursor()
    rect(cx*(fw+1)+1,blink and cy*(fh+1)+1 or cy*(fh+1),fw+1,blink and fh-1 or fh+3,false,blink and 4 or c) --The blink
  end
  
  for event,a,b,c,d,e,f in pullEvent do
    if event == "textinput" then
      t = t .. a
      print(a,false)
    elseif event == "keypressed" then
      if a == "backspace" then
        blink = false; drawblink()
        if t:len() > 0 then printBackspace() end
        blink = true; drawblink()
        t = t:sub(0,-2)
      elseif a == "return" then
        blink = false; drawblink()
        return t --Return the text
      elseif a == "escape" then
        return false --User canceled text input.
      end
    elseif event == "touchpressed" then
      textinput(true)
    elseif event == "update" then --Blink
      blinktimer = blinktimer + a
      if blinktimer > blinktime then
        blinktimer = blinktimer - blinktime
        blink = not blink
        drawblink()
      end
    end
  end
end
setfenv(glob.input,glob) --Set the function environment.

--Third-Party Libraries
local Library = glob.Library
glob.Library = nil

glob.lume = Library("lume")
glob.class = Library("class")
glob.bump = Library("bump")
glob.likocam = Library("likocam")
glob.JSON = Library("JSON")
glob.luann = Library("luann")
glob.geneticAlgo = Library("geneticAlgo")
glob.vector = Library("vector")
glob.SpriteSheet = Library("spritesheet")