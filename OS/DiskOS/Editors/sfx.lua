--SFX Editor

local eapi = select(1,...)

local se = {} --sfx editor

local sfxSlots = 64
local sfxNotes = 48

local defaultNoteTime = 1/sfxNotes
local noteTime = defaultNoteTime

local sfxdata = {}
for i=0,sfxSlots-1 do
  sfxdata[i] = {}
  for i=1,sfxNotes*4, 4 do
    sfxdata[i] = defaultNoteTime --Time
    sfxdata[i+1] = -1  --Waveform
    sfxdata[i+2] = 0  --Frequency
    sfxdata[i+3] = 1  --Amplitude
  end
end

function se:entered()
  eapi:drawUI()
end

function se:leaved()
  
end

return se