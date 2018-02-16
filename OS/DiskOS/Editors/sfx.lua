--SFX Editor

local sfxobj = require("Libraries.sfx")

local eapi = select(1,...)

local sw, sh = screenSize()

local se = {} --sfx editor

local sfxSlots = 64
local sfxNotes = 64

local defaultSpeed = 1
local speed = defaultSpeed

local sfxdata = {}
for i=0,sfxSlots-1 do
  sfxdata[i] = sfxobj(sfxNotes, defaultSpeed)
end

local selectedSlot = 0

local pitchGrid = {0,9, sfxNotes*2,12*8, sfxNotes,12*8}

local function drawPitch()
  local x,y = pitchGrid[1], pitchGrid[2]-1
  local sfx = sfxdata[selectedSlot]
  
  --Box Rectangle
  rect(x,y,sfxNotes*2+1,12*8+2,false,0)
  
  --Notes lines
  for i=0, sfxNotes-1 do
    local note,oct,wave = sfx:getNote(i); note = note-1
    line(x+1+i*2, y+12*8-(note+oct*12), x+1+i*2, y+12*8, 7)
    point(x+1+i*2, y+12*8-(note+oct*12),8+wave)
    point(x+1+i*2, y+12*8-(note+oct*12)+1,8+wave)
  end
  
  --Outline
  rect(x,y,sfxNotes*2+1,12*8+2,true,0)
end

function se:entered()
  eapi:drawUI()
  drawPitch()
  cursor("point",true)
end

function se:leaved()
  
end

function se:pitchMouse(state,x,y,button,istouch)
  local cx,cy = whereInGrid(x,y,pitchGrid)
  if cx and isMDown(1) then
    local sfx = sfxdata[selectedSlot]
    cx, cy = cx-1, 12*8-cy+1
    local note = cy%12
    local oct = math.floor(cy/12)
    sfx:setNote(cx,note,oct)
    drawPitch()
  end
end

se.keymap = {
  ["p"] = function()
    sfxdata[selectedSlot]:play()
    cprint("play !")
  end
}

function se:mousepressed(x,y,button,istouch)
  self:pitchMouse("pressed",x,y,button,istouch)
end

function se:mousemoved(x,y,button,istouch)
  self:pitchMouse("moved",x,y,dx,dy,istouch)
end

function se:mousereleased(x,y,button,istouch)
  self:pitchMouse("released",x,y,button,istouch)
end

return se