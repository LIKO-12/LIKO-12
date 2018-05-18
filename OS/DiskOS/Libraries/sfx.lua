--SFX Object--

local function newSFX(notes,speed)
  
  local sfx = {}
  
  sfx.notes = notes or 32
  sfx.speed = speed or 1
  sfx.notetime = sfx.speed/sfx.notes
  
  --Initialize the sfx data.
  for i=1,sfx.notes*4, 4 do
    sfx[i] = sfx.notetime
    sfx[i+1] = 0
    sfx[i+2] = 0
    sfx[i+3] = 1
  end
  
  function sfx:setNote(id,note,oct,waveform,volume)
    if note and oct then
      local freq = AudioUtils.noteFrequency(note,oct)
      self[id*4 + 3] = freq
    end
    
    if waveform then
      self[id*4 + 2] = waveform
    end
    
    if volume then
      self[id*4 + 4] = math.min(math.abs(volume), 1)
    end
    
    return self
  end
  
  function sfx:getNote(id)
    local note,oct = AudioUtils.frequencyNote(self[id*4 + 3])
    
    return note,oct,self[id*4 + 2],self[id*4 + 4]
  end
  
  function sfx:_updateDataTime()
    for i=1,sfx.notes*4,4 do
      sfx[i] = sfx.notetime
    end
  end
  
  function sfx:setSpeed(speed)
    self.speed = speed
    self.notetime = self.speed/self.notes
    self:_updateDataTime()
    
    return self
  end
  
  function sfx:getSpeed()
    return self.speed
  end
  
  function sfx:setNoteTime(time)
    self.notetime = time
    self.speed = self.notetime*self.notes
    self:_updateDataTime()
    
    return self
  end
  
  function sfx:getNoteTime()
    return self.notetime
  end
  
  function sfx:play(chn)
    if Audio then Audio.play(self,chn or 0) end
    
    return self
  end
  
  local notesL = {
    "C ","C#","D ","D#","E ","F ","F#","G ","G#","A ","A#","B "
  }
  
  for k,v in ipairs(notesL) do
    notesL[v] = k
  end
  
  local toFreq = AudioUtils.frequencyNote
  local toNote = AudioUtils.noteFrequency
  local floor = math.floor
  
  function sfx:export()
    local data, dpos = {floor(self.speed/0.25),":"}, 3
    for i=1, self.notes*4, 4 do
      local n,o = toFreq(self[i+2])
      data[dpos] = notesL[n]
      data[dpos+1] = o
      data[dpos+2] = self[i+1]
      data[dpos+3] = floor(self[i+3]*7)
      data[dpos+4] = ","
      dpos = dpos+5
    end
    return table.concat(data)
  end
  
  function sfx:encode()
    local Write = BinUtils.binWriter()
    Write(floor(self.speed/0.25),8)
    for i=1, self.notes*4, 4 do
      local n,o = toFreq(self[i+2])
      Write(n-1, 4) --Note
      Write(o, 3) --Octave
      Write(self[i+1], 3) --Instrument
      Write(floor(self[i+3]*7), 3) --Volume
    end
    return Write()
  end
  
  function sfx:import(data)
    
    local speed, notes = data:match("(%d*):(.*)")
    
    self.speed = tonumber(speed)*0.25
    local nt = self.speed/self.notes
    self.notetime = nt
    
    local id = -3
    for note in notes:gmatch("(.-),") do
      id = id + 4
      self[id] = nt
      self[id+1] = tonumber(note:sub(4,4))
      self[id+2] = toNote(notesL[note:sub(1,2)], tonumber(note:sub(3,3)))
      self[id+3] = tonumber(note:sub(5,5))/7
    end
  end
  
  function sfx:decode(data)
    local Read = BinUtils.binReader(data)
    
    self.speed = tonumber(Read(8))*0.25
    local nt = self.speed/self.notes
    self.notetime = nt
    
    for i=1, self.notes*4, 4 do
      local n = Read(4)+1 --Note
      local o = Read(3) --Octave
      self[i+2] = toNote(n,o) --Frequency
      self[i+1] = Read(3) --Waveform
      self[i+3] = Read(3)/7 --Amplitude
      self[i] = nt
    end
  end
  
  return sfx
  
end

return newSFX