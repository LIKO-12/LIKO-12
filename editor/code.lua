local cedit = {}

local colorize = require("Libraries.colorize_lua")

cedit.colors = {
text = _GetColor(8),
keyword = _GetColor(15),
number = _GetColor(13),
comment = _GetColor(14),
str = _GetColor(13),
}

cedit.codebuffer = {""}
cedit.lineLimit = 14
cedit.cursorX, cedit.cursorY = 1,1
cedit.topLine = 0

local lastCursorX = 1

local blinktime = 0.5
local blinktimer = 0
local blinkstate = false

function cedit:_switch()
  
end

function cedit:_redraw()
  rect(1,9,192,128-16,6) color(7)
  local tocolor = {}
  for i=self.topLine+1,self.topLine+self.lineLimit do
    if self.codebuffer[i] then table.insert(tocolor,self.codebuffer[i]) end
  end
  local colored = colorize(tocolor,self.colors)
  color(8)
  for line,text in ipairs(colored) do
    print_grid(text,1,line+1)
  end
  
  --[[for i=self.topLine+1,self.topLine+self.lineLimit do
    if self.codebuffer[i] then print_grid(self.codebuffer[i],1,(i-self.topLine)+1) end
  end]]
end

function cedit:_update(dt)
  blinktimer = blinktimer+dt if blinktimer > blinktime then blinktimer = blinktimer - blinktime  blinkstate = not blinkstate end
  local curlen = self.codebuffer[self.topLine+self.cursorY]:len()
  if blinkstate then rect((self.cursorX-1)*4+2,(self.cursorY)*8+2,4,5,9) else self:_redraw() end
end

function cedit:_kpress(k,sc,ir)
  if k == "return" then
    if self.cursorY == self.lineLimit then --check if the cursor is at the last line
      self.topLine = self.topLine+1 --In that case
    else
      self.cursorY = self.cursorY+1
    end
    for i=#self.codebuffer, self.cursorY+self.topLine, -1 do self.codebuffer[i+1] = self.codebuffer[i] end--Shift down the code
    self.codebuffer[self.cursorY+self.topLine] = "" --Insert a new empty line
    self.cursorX, blinktimer, blinkstate = 1, 0, true --Set the cursorX to 1 (since it's an empty line), also reset the blinkstate&timer to force the cursor to blink on
    self:_redraw() --Update the screen content for the user
  elseif k == "backspace" then
    if self.codebuffer[self.cursorY+self.topLine] == "" then
      if self.cursorY ~= 1 then
        table.remove(self.codebuffer,self.cursorY+self.topLine) --Remove the line so the table size stays correct
        if self.cursorY == 1 then
         self.topLine = self.topLine-1
         if self.topLine < 1 then self.topline=0 end
        else
         self.cursorY = self.cursorY-1
        end
        self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1
      end
    else
      self.codebuffer[self.cursorY+self.topLine] = self.codebuffer[self.cursorY+self.topLine]:sub(0,self.cursorX-2)..self.codebuffer[self.cursorY+self.topLine]:sub(self.cursorX,-1)--self.codebuffer[self.cursorY+self.topLine]:sub(0,-2)
      self.cursorX = self.cursorX-1
    end
    blinktimer, blinkstate = 0, true
    self:_redraw()
  elseif k == "up" then
    self.cursorY = self.cursorY-1
    if self.cursorY < 1 then if self.topLine > 0 then self.topLine = self.topLine -1 end self.cursorY = 1 end
    if ir then self.cursorX = lastCursorX else lastCursorX = self.cursorX end
    if self.cursorX > self.codebuffer[self.cursorY+self.topLine]:len()+1 then self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1 end
    blinktimer, blinkstate = 0, true
    self:_redraw()
  elseif k == "down" then
    blinktimer, blinkstate = 0, true
    if self.cursorY+self.topLine == #self.codebuffer then return end
    if self.cursorY == self.lineLimit then
      self.topLine = self.topLine+1
    else
      self.cursorY = self.cursorY+1
    end
    if ir then self.cursorX = lastCursorX else lastCursorX = self.cursorX end
    if self.cursorX > self.codebuffer[self.cursorY+self.topLine]:len()+1 then self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1 end
    self:_redraw()
  elseif k == "left" then
    self.cursorX = self.cursorX - 1
    if self.cursorX < 1 then self.cursorX = 1 end
    blinktimer, blinkstate = 0, true
    self:_redraw()
  elseif k == "right" then
    self.cursorX = self.cursorX + 1
    if self.cursorX > self.codebuffer[self.topLine+self.cursorY]:len() then self.cursorX = self.codebuffer[self.topLine+self.cursorY]:len()+1 end
    blinktimer, blinkstate = 0, true
    self:_redraw()
  end
end

function cedit:_krelease(k,sc)
  lastCursorX = 1
end

function cedit:_tinput(t)
  blinktimer, blinkstate = 0, true
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