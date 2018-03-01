--Audio Utilities

--Localized Lua Library
local floor = math.floor

--The API
local AudioUtils = {}

-- C# D#   F# G# A#
--C  D  E F  G  A  B

--Convert from waveform id to waveform name, and vice versa.
AudioUtils.Waves = {
  "Square", "Pulse", "Sawtooth", "Triangle", "Noise";
  [-1] = "Silent", [0] = "Sine"
}

for i=-1,5 do
  AudioUtils.Waves[AudioUtils.Waves[i]] = i
end

--Convert from note letter to note number and vice versa.
AudioUtils.Notes = {
 "C","C#","D","D#","E","F","F#","G","G#","A","A#","B"
}

for i=1,12 do
  AudioUtils.Notes[AudioUtils.Notes[i]] = i
end

--Convert from note+oct to frequency.
--note can be the note name or note number (1,12), oct can be from 0 to 7.
local noteFreqConst, noteFreqCache = 2^(1/12), {}
function AudioUtils.noteFrequency(note,oct)
  
  if type(note) == "string" then
    note = AudioUtils.Notes[note]
  end
  
  note,oct = floor(note), floor(oct)
  
  if noteFreqCache[note.."x"..oct] then return noteFreqCache[note.."x"..oct] end
 
  local notepos = (oct)*12+note
  local notedist = notepos - 58
  local notehz = 440 --A4
  
  if notedist < 0 then
    for i=1,-notedist do
      notehz = notehz/noteFreqConst
    end
  elseif notedist > 0 then
    for i=1,notedist do
      notehz = notehz*noteFreqConst
    end
  end
  
  noteFreqCache[note.."x"..oct] = notehz
  
  return notehz
  
end

function AudioUtils.frequencyNote(freq)
  
  for oct=0,7 do
    for note=1,12 do
      local nfreq = AudioUtils.noteFrequency(note,oct)
      
      if nfreq >= freq then
        return note, oct
      end
    end
  end
  
  return 12, 7
  
end

--Make the AudioUtils a global
_G["AudioUtils"] = AudioUtils