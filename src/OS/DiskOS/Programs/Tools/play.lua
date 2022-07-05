if (...) and (...) == "-?" then
  printUsage("play <note> [time] [waveform]","Play a music note for an amount of time.")
  return
end

local note, time, wave = ...
time = time or "1"
wave = wave or "0"

if not note then print("Notes: C C# D D# E F F# G G# A A# B") return end

if #note == 1 then
  note = note .. "4"
elseif #note == 2 then
  if not tonumber(note:sub(-1,-1)) then
    note = note .. "4"
  end
end

local oct = note:sub(-1,-1)
note = note:sub(1,-2)

if not AudioUtils.Notes[note:upper()] then
  if (not tonumber(note)) or (not AudioUtils.Notes[tonumber(note)]) then
    return 1, "Invalid note: "..tostring(note)
  end
end

if not tonumber(oct) then return 1, "Invalid octave: "..oct end
oct = math.floor(tonumber(oct))
if oct > 8 or oct < 0 then return 1, "Invalid octave: "..oct end

if not tonumber(note) then note = AudioUtils.Notes[note:upper()] end

if not tonumber(time) then return 1, "Invalid Time: "..tostring(time) end
time = tonumber(time)

if time <= 0 then return end --Nothing to play

wave = wave:sub(1,1):upper()..wave:sub(2,-1):lower()
if not AudioUtils.Waves[wave] then
  if (not tonumber(wave)) or (not AudioUtils.Waves[tonumber(wave)]) then
    return 1, "Invalid waveform: "..tostring(wave)
  end
end

if not tonumber(wave) then wave = AudioUtils.Waves[wave] end
wave = tonumber(wave)

local freq = AudioUtils.noteFrequency(note,oct)

if Audio then Audio.play({time,wave,freq,1}) end
sleep(time)