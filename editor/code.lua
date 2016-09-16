local cedit = {}

cedit.codebuffer = {}
setmetatable(cedit.codebuffer,{__index=function() return "" end})
cedit.lineLimit = 14
cedit.cursorX, cedit.cursorY = 1,1
cedit.topLine = 0

local blinktime = 0.5
local blinktimer = 0
local blinkstate = false

function cedit:_switch()
  
end

function cedit:_redraw()
  rect(1,9,192,128-16,6) color(7)
  for i=self.topLine+1,self.topLine+1+self.lineLimit do
    print_grid(self.codebuffer[i],1,(i-self.topLine)+1)
  end
  
end

function cedit:_update(dt)
  blinktimer = blinktimer+dt if blinktimer > blinktime then blinktimer = blinktimer - blinktime  blinkstate = not blinkstate end
  local curlen = self.codebuffer[self.topLine+self.cursorY]:len()
  --if blinkstate then rect(curlen > 0 and ((curlen)*4+3) or 2,(self.cursorY)*8+2,4,5,9) else self:_redraw() end
  if blinkstate then rect((self.cursorX-1)*4+2,(self.cursorY)*8+2,4,5,9) else self:_redraw() end
end

function cedit:_kpress(k,sc,ir)
  if k == "return" then
    if self.cursorY == self.lineLimit then
      self.topLine = self.topLine+1
    else
      self.cursorY = self.cursorY+1
    end
    if self.cursorX > self.codebuffer[self.cursorY+self.topLine]:len()+1 then self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1 end
    self:_redraw()
  elseif k == "backspace" then
    if self.codebuffer[self.cursorY+self.topLine] == "" then
      if self.cursorY == 1 then
       self.topLine = self.topLine-1
       if self.topLine < 1 then self.topline=0 end
      else
       self.cursorY = self.cursorY-1
      end
      self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1
    else
      self.codebuffer[self.cursorY+self.topLine] = self.codebuffer[self.cursorY+self.topLine]:sub(0,self.cursorX-2)..self.codebuffer[self.cursorY+self.topLine]:sub(self.cursorX,-1)--self.codebuffer[self.cursorY+self.topLine]:sub(0,-2)
      self.cursorX = self.cursorX-1
    end
    self:_redraw()
  elseif k == "up" then
    
  elseif k == "down" then
    
  elseif k == "left" then
    self.cursorX = self.cursorX - 1
    if self.cursorX < 1 then self.cursorX = 1 end
    self:_redraw()
  elseif k == "right" then
    self.cursorX = self.cursorX + 1
    if self.cursorX > self.codebuffer[self.topLine+self.cursorY]:len() then self.cursorX = self.codebuffer[self.topLine+self.cursorY]:len()+1 end
    self:_redraw()
  end
end

function cedit:_tinput(t)
  if self.codebuffer[self.cursorY+self.topLine]:len() == 46 then return end
  self.codebuffer[self.cursorY+self.topLine] = self.codebuffer[self.cursorY+self.topLine]:sub(0,self.cursorX-1)..t..self.codebuffer[self.cursorY+self.topLine]:sub(self.cursorX,-1)--self.codebuffer[self.cursorY+self.topLine]..t
  self.cursorX = self.cursorX+1
  self:_redraw()
end

function cedit:_tpress()
  --This means the user is using a touch device
  self.lineLimit = 7
  love.keyboard.setTextInput(true)
end

return cedit