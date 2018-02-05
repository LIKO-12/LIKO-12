--SFX Object--

local function newSFX(notes,speed)
  
  local sfx = {}
  
  sfx.notes = notes or 48
  sfx.speed = speed or 1
  sfx.notetime = sfx.speed/sfx.notes
  
  --Initialize the sfx data.
  for i=1,sfx.notes*4, 4 do
    sfx[i] = sfx.notetime
    sfx[i+1] = -1
    sfx[i+2] = 0
    sfx[i+3] = 1
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
  end
  
  function sfx:getSpeed()
    return self.speed
  end
  
  function sfx:setNoteTime(time)
    self.notetime = time
    self.speed = self.notetime*self.notes
    self:_updateDataTime()
  end
  
  function sfx:getNoteTime()
    
  end
  
end

return newSFX