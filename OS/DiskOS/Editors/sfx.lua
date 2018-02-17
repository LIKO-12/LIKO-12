--SFX Editor

local sfxobj = require("Libraries.sfx") --The sfx object

local eapi = select(1,...) --The editors api

local sw, sh = screenSize() --The screensize

local se = {} --sfx editor

local sfxSlots = 64 --The amount of sfx slots
local sfxNotes = 32 --The number of notes in each sfx

local defaultSpeed = 0.25 --The default speed
local speed = defaultSpeed --The current sfx speed

--The SFXes datas.
local sfxdata = {}
for i=0,sfxSlots-1 do
  local sfx = sfxobj(sfxNotes, defaultSpeed)
  for i=0,sfxNotes-1 do
    sfx:setNote(i,1,1,-1,0) --Octave 0 is hidden...
  end
  sfxdata[i] = sfx
end

local selectedSlot = 0
local playingNote = -1

local pitchGrid = {2,9, sfxNotes*4,12*7, sfxNotes,12*7}

local function drawPitch()
  local x,y = pitchGrid[1], pitchGrid[2]-1
  local sfx = sfxdata[selectedSlot]
  
  --Box Rectangle
  rect(x,y,pitchGrid[3],pitchGrid[4]+4,false,0)
  
  local playingNote = math.floor(playingNote)
  
  --Notes lines
  for i=0, sfxNotes-1 do
    local note,oct,wave = sfx:getNote(i); note = note-1
    if wave >= 0 then
      rect(x+1+i*4, y+12*8-(note+oct*12), 2, note+oct*12-9, false, (playingNote == i and 6 or 1))
      rect(x+1+i*4, y+12*8-(note+oct*12), 2, 2, false, 8+wave)
    end
  end
end

function se:entered()
  eapi:drawUI()
  drawPitch()
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
    sfx:setNote(cx,note,oct,0,1)
    drawPitch()
  end
end

se.keymap = {
  ["space"] = function()
    sfxdata[selectedSlot]:play()
    playingNote = 0
  end
}

function se:update(dt)
  if playingNote >= 0 then
    playingNote = playingNote + (dt*sfxNotes)/speed
    if playingNote >= sfxNotes then
      playingNote = -1
    end
    drawPitch()
  end
end

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