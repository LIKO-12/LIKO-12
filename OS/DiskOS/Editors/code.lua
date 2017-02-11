local eapi = select(1,...) --The editor library is provided as an argument

local ce = {} --Code editor

local buffer = {""} --A table containing lines of code

local screenW, screenH = screenSize()
local lume = require("C://Libraries/lume")
local clua = require("C://Libraries/colorize_lua")
local cluacolors = {
text = 8,
keyword = 11,
number = 13,
comment = 14,
str = 13
}

ce.bgc = 6--Background Color
ce.cx, ce.cy = 1, 1 --Cursor Position
ce.tw, ce.th = termSize() --The terminal size
ce.th = ce.th-2 --Because of the top and bottom bars
ce.vx, ce.vy = 1,1 --View postions

ce.btimer = 0 --The cursor blink timer
ce.btime = 0.5 --The cursor blink time
ce.bflag = true --The cursor is blinking atm ?

--A usefull print function with color support !
function ce:colorPrint(tbl)
  pushColor()
  for i=1, #tbl, 2 do
    local col = tbl[i]
    local txt = tbl[i+1]
    color(col)
    print(txt,false,true)--Disable auto newline
  end
  --print("")--A new line
  popColor()
end

--Check the position of the cursor so the view includes it
function ce:checkPos()
  --X position checking--
  if self.cx > self.tw + (self.vx-1) then --Passed the screen to the right
    self.vx = self.cx - (self.tw-1)
  elseif self.cx < self.vx then --Passed the screen to the left
    self.vx = self.cx
  end
  
  --Y position checking--
  if self.cy > #buffer then self.cy = #buffer end --Passed the end of the file
  
  if self.cy > self.th + self.vy-1 then --Passed the screen to the bottom
    self.vy = self.cy - (self.th-1)
  elseif self.cy < self.vy then --Passed the screen to the top
    if self.cy < 1 then
      self.cy = 1
    else
      self.vy = self.cy
    end
  end
end

--Draw the cursor blink
function ce:drawBlink()
  if self.bflag then
    rect((self.cx-self.vx+1)*4-2,(self.cy-self.vy+1)*8+2, 4,5, false, 5)
  end
end

--Draw the code on the screen
function ce:drawBuffer()
  local cbuffer = clua(lume.clone(lume.slice(buffer,self.vy,self.vy+self.th)),cluacolors)
  rect(1,9,screenW,screenH-8*2,false,self.bgc)
  for k, l in ipairs(cbuffer) do
    printCursor(-(self.vx-2),k+1,0)
    self:colorPrint(l)
  end
  self:drawBlink()
end

function ce:drawLine()
  local cline = clua({buffer[self.cy]},cluacolors)
  rect(1,(self.cy-self.vy+2)*8-7, screenW,7, false,self.bgc)
  printCursor(-(self.vx-2),(self.cy-self.vy+1)+1,self.bgc)
  self:colorPrint(cline[1])
  self:drawBlink()
end

function ce:textinput(t)
  buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)..t..buffer[self.cy]:sub(self.cx,-1)
  self.cx = self.cx + t:len()
  self:checkPos()
  self:drawLine()
end

ce.keymap = {
  ["return"] = function(self)
    self.cx, self.cy = 1, self.cy+1
    if self.cy > #buffer then
      table.insert(buffer,"")
    else
      buffer = lume.concat(lume.slice(buffer,0,self.cy-1),{""},lume.slice(buffer,self.cy,-1))
    end
    self:checkPos()
    self:drawBuffer()
  end,
  ["left"] = function(self)
    if self.cx > 1 then 
      self.cx = self.cx - 1
    end
    self:checkPos()
    self:drawLine()
  end,
  ["right"] = function(self)
    if self.cx < self.tw then
      self.cx = self.cx + 1
    end
    self:checkPos()
    self:drawLine()
  end,
  ["backspace"] = function(self)
    if self.cx > 1 then 
      self.cx = self.cx - 1
    end
    buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)
    self:checkPos()
    self:drawLine()
  end
}

function ce:entered()
  eapi:drawUI()
  ce:drawBuffer()
end

function ce:leaved()
  
end

function ce:touchpressed() textinput(true) end

function ce:update(dt)
  --Blink timer
  self.btimer = self.btimer + dt
  if self.btimer >= self.btime then
    self.btimer = self.btimer - self.btime
    self.bflag = not self.bflag
    self:drawLine() --Redraw the current line
  end
end

return ce