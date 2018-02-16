--SFX Object--

local function newSFX(notes,speed)
  
  local sfx = {}
  
  sfx.notes = notes or 48
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
    Audio.play(self,chn or 0)
    
    return self
  end
  
  return sfx
  
end

return newSFX