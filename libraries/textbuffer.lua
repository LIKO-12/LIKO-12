--This library is create for programming code editors in liko-12 more easly by using premade text buffer with horizental and vertical scrolling support--

local tb = _Class("liko12.textBuffer")

--Args: grid x, grid Y, draw width in grid, draw height in grid, lines Limit, length Limit, min length, cursor color, blinktime--
--0 blinktime disables cursor, 0 lines limit, 0 length disables all that..--
--TODO: add real lines & length & mlength limits.--
function tb:initialize(gx,gy,gw,gh,linel,lengthl,mlength,curcol,blinktime)
  self.gx, self.gy, self.linel, self.lenl, self.minl, self.curcol, self.blinktime = gx or 1, gy or 1, linel or 16, lengthl or 47, mlength or 0, curcol or 5, blinktime or 0.5
  self.gw, self.gh = gw or self.lenl, gh or self.linel
  self.buffer = {""} --Start with an empty line
  self.blinktimer = 0
  self.blinkstate = 0
  
  self.cursorX, self.cursorY = 1,1
  self.lastCX = 1 --Last cursor x when scrolling up or down
  
  self.shiftRight = 0
  self.shiftTop = 0
  
  self.keymap = {
    ["return"] = function(self,ir)
      self:shiftDown(self.cursorY+1)
      self.buffer[self.cursorY+1] = self.buffer[self.cursorY]:sub(self.cursorX,-1)
      self.buffer[self.cursorY] = self.buffer[self.cursorY]:sub(0,self.cursorX-1)
      self.cursorY = self.cursorY+1
      self.cursorX = 1
    end,
    
    ["backspace"] = function(self,ir)
      if self.cursorX == 1 then --If it's at the start of the line
        if self.buffer[self.cursorY-1] then
          self.cursorX = self.buffer[self.cursorY-1]:len()+1
          self.buffer[self.cursorY-1] = self.buffer[self.cursorY-1]..self.buffer[self.cursorY]
          self:shiftUp(self.cursorY+1)
          self.cursorY = self.cursorY-1
        end
      else
        self.buffer[self.cursorY] = self.buffer[self.cursorY]:sub(0,self.cursorX-2)..self.buffer[self.cursorY]:sub(self.cursorX,-1)
        self.cursorX = self.cursorX-1
      end
    end,
    
    ["left"] = function(self,ir)
      self.cursorX = self.cursorX-1
      if self.cursorX < 1 then
        if self.buffer[self.cursorY-1] then
          self.cursorX = self.buffer[self.cursorY-1]:len()+1
          self.keymap["up"](self,false)
        else
          self.cursorX = 1
        end
      end
    end,
    
    ["right"] = function(self,ir)
      self.cursorX = self.cursorX+1
      if self.cursorX > self.buffer[self.cursorY]:len()+1 then
        if self.buffer[self.cursorY+1] then
          self.cursorX = 1
          self.keymap["down"](self,false)
        else
          self.cursorX = self.buffer[self.cursorY]:len()+1
        end
      end
    end,
    
    ["up"] = function(self,ir)
      if self.buffer[self.cursorY-1] then
        self.cursorY = self.cursorY-1
        if not ir then self.lastCX = self.cursorX else self.cursorX = self.lastCX end
        if self.cursorX > self.buffer[self.cursorY]:len()+1 then self.cursorX = self.buffer[self.cursorY]:len()+1 end
      end
    end,
    
    ["down"] = function(self,ir)
      if self.buffer[self.cursorY+1] then
        self.cursorY = self.cursorY+1
        if not ir then self.lastCX = self.cursorX else self.cursorX = self.lastCX end
        if self.cursorX > self.buffer[self.cursorY]:len()+1 then self.cursorX = self.buffer[self.cursorY]:len()+1 end
      end
    end,
    
    ["home"] = function(self,ir)
      self.cursorX = 1
    end,
    
    ["end"] = function(self,ir)
      self.cursorX = self.buffer[self.cursorY]:len()+1
    end,
    
    ["pageup"] = function(self,ir)
      for i=1, self.gh do
        
      end
    end,
    
    ["pagedown"] = function(self,ir)
      
    end
  }
  
end

function tb:_update(dt)
  if self.blinktime == 0 then return end
  self.blinktimer = self.blinktimer+dt if self.blinktimer > self.blinktime then self.blinktimer = self.blinktimer - self.blinktime  self.blinkstate = not self.blinkstate end
  local curlen = self.buffer[self.cursorY]:len()
  if self.blinkstate then api.rect((self.cursorX-1-self.shiftRight)*4+2,(self.cursorY-self.shiftTop)*8+2,4,5,self.curcol) else self:_redraw() end
end

function tb:_redraw()
  local dbuff = self:getDrawBuffer()
  for line,text in ipairs(debuff) do
    api.print_grid(line,self.gx,self.gy)
  end
end

function tb:_tinput(t)
  self:forceBlink()
  --print(self.buffer[self.cursorY]:sub(0,self.cursorX-1)..t..self.buffer[self.cursorY]:sub(self.cursorX,-1))
  if self.lenl > 0 and self.buffer[self.cursorY]:len()-1 > self.lenl then return end
  self.buffer[self.cursorY] = self.buffer[self.cursorY]:sub(0,self.cursorX-1)..t..self.buffer[self.cursorY]:sub(self.cursorX,-1)
  self.cursorX = self.cursorX + t:len()
  self:_redraw()
end

function tb:getBuffer()
  local bclone = {}
  for line,text in ipairs(self.buffer) do
    table.insert(bclone,text)
  end
  return bclone
end

function tb:getLinesBuffer()
  self:fixShifts()
  local dbuff = {}
  for y=self.shiftTop+1,self.shiftTop+1+self.gh do
    if self.buffer[y] then
      table.insert(dbuff,self.buffer[y])
    end
  end
  return dbuff, self.gx, self.gy, self.shiftRight
end

function tb:getDrawBuffer()
  self:fixShifts()
  local dbuff = {}
  for y=self.shiftTop+1,self.shiftTop+1+self.gh do
    if self.buffer[y] then
      table.insert(dbuff,self.buffer[y]:sub(self.shiftRight,self.shiftRight+self.gw))
    end
  end
  return dbuff, self.gx, self.gy
end

function tb:fixShifts()
  if self.cursorX > self.shiftRight+self.gw then self.shiftRight =  self.cursorX - self.gw end
  if self.cursorY > self.shiftTop+self.gh then self.shiftTop =  self.cursorY - self.gh end
  
  if self.cursorX <= self.shiftRight then self.shiftRight =  self.cursorX-1 end
  if self.cursorY <= self.shiftTop then self.shiftTop =  self.cursorY-1 end
  self.shiftRight =  api.floor(self.shiftRight)
  self.shiftTop =  api.floor(self.shiftTop)
end

function tb:forceBlink() self.blinktimer, self.blinkstate = 0, true end

function tb:shiftDown(sline) --Note: the sline is shifted
  if sline > #self.buffer then table.insert(self.buffer,"") return end
  table.insert(self.buffer,"") -- Insert a new line
  for i=#self.buffer-1,sline,-1 do
    self.buffer[i+1] = self.buffer[i]
  end
  self.buffer[sline] = "" --Clear the start line
  return self
end

function tb:shiftUp(sline)
  if sline == 1 then return end
  for i=sline,#self.buffer do --Note: the sline is shifted
    self.buffer[i-1] = self.buffer[i]
  end
  table.remove(self.buffer,#self.buffer) --Remove the last line
end

return tb