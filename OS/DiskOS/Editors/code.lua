local eapi = select(1,...) --The editor library is provided as an argument

--=Contributing Guide=--
--[[
Try your best to keep your work light, documented and teady, sine this will be the base of other places where text editors exists.

self.cx, self.cy are the position of the brown blinking cursor
* the top-left corner pos is 1, 1
You don't have to take care when the cursor is out of range
You only have to call self:checkPos() whenever you change self.cx or self.cy
Note that when you call checkPos it will return you a boolean value
if this is true: You have to call self:drawBuffer()
if this is false: It's enough to call self:drawLine()
Lua code: if self:checkPos() then self:drawBuffer() else self:drawLine() end
Note: when you change the self.cy you have to drawBuffer, because it may left the brown cursor rect.

self:drawBuffer() draws all visible lines
self:drawLine() will only draw the line of self.cy

self.vx, self.vy are the position of the top-left corner of the visible area in the editor
You don't have to take care of this when working with self:checkPos()
But if you ever wanted to change the v pos where blinking cursor is not visible you have to edit checkPos for that somehow
Infact self:checkPos() returns true whenever it changes vx, vy or cy
So you will have to self:drawBuffer() for that

Be sure to read the contributing guide in Editors/init.lua

==Contributers to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

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

ce.sw, ce.sh = screenSize()
local charGrid = {1,9, ce.sw,ce.sh-16, ce.tw, ce.th}

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
  local flag = false --Flag if the whole buffer requires redrawing
  --Y position checking--
  if self.cy > #buffer then self.cy = #buffer end --Passed the end of the file
  
  if self.cy > self.th + self.vy-1 then --Passed the screen to the bottom
    self.vy = self.cy - (self.th-1); flag = true
  elseif self.cy < self.vy then --Passed the screen to the top
    if self.cy < 1 then self.cy = 1 end
    self.vy = self.cy; flag = true
  end
  
  --X position checking--
  if buffer[self.cy]:len() < self.cx-1 then self.cx = buffer[self.cy]:len()+1 end --Passed the end of the line !
  
  if self.cx > self.tw + (self.vx-1) then --Passed the screen to the right
    self.vx = self.cx - (self.tw-1); flag = true
  elseif self.cx < self.vx then --Passed the screen to the left
    if self.cx < 1 then self.cx = 1 end
    self.vx = self.cx; flag = true
  end
  
  return flag
end

--Draw the cursor blink
function ce:drawBlink()
  if self.bflag then
    rect((self.cx-self.vx+1)*4-2,(self.cy-self.vy+1)*8+2, 4,5, false, 5)
  end
end

--Draw the code on the screen
function ce:drawBuffer()
  local cbuffer = clua(lume.clone(lume.slice(buffer,self.vy,self.vy+self.th-1)),cluacolors)
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
  if self:checkPos() then self:drawBuffer() else self:drawLine() end
end

ce.keymap = {
  ["return"] = function(self)
    local newLine = buffer[self.cy]:sub(self.cx,-1)
    buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)
    self.cx, self.cy = 1, self.cy+1
    if self.cy > #buffer then
      table.insert(buffer,newLine)
    else
      buffer = lume.concat(lume.slice(buffer,0,self.cy-1),{newLine},lume.slice(buffer,self.cy,-1)) --Insert between 2 different lines
    end
    self:checkPos()
    self:drawBuffer()
  end,
  
  ["left"] = function(self)
    local flag = false
    self.cx = self.cx -1
    if self.cx < 1 then
      if self.cy > 1 then
        self.cy = self.cy -1
        self.cx = buffer[self.cy]:len()+1
        flag = true
      end
    end
    if self:checkPos() or flag then self:drawBuffer() else self:drawLine() end
  end,
  
  ["right"] = function(self)
    local flag = false
    self.cx = self.cx +1
    if self.cx > buffer[self.cy]:len()+1 then
      if buffer[self.cy+1] then
        self.cy = self.cy +1
        self.cx = 1
        flag = true
      end
    end
    if self:checkPos() or flag then self:drawBuffer() else self:drawLine() end
  end,
  
  ["up"] = function(self)
    self.cy = self.cy -1
    self:checkPos()
    self:drawBuffer()
  end,
  
  ["down"] = function(self)
    self.cy = self.cy +1
    self:checkPos()
    self:drawBuffer()
  end,
  
  ["backspace"] = function(self)
    if self.cx == 1 then
      if self.cy > 1 then
        self.cx = buffer[self.cy-1]:len()+1
        buffer[self.cy-1] = buffer[self.cy-1] .. buffer[self.cy]
        buffer = lume.concat(lume.slice(buffer,0,self.cy-1),lume.slice(buffer,self.cy+1,-1))
        self.cy = self.cy-1
        self:checkPos()
        self:drawBuffer()
      end
    else
      buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-2) .. buffer[self.cy]:sub(self.cx, -1)
      self.cx = self.cx-1
      if self:checkPos() then self:drawBuffer() else self:drawLine() end
    end
  end,
  
  ["home"] = function(self)
    self.cx = 1
    self:checkPos()
    self:drawLine()
  end,
  
  ["end"] = function(self)
    self.cx = buffer[self.cy]:len()+1
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

function ce:mousepressed(x, y, button, istouch)
  local cx, cy = whereInGrid(x,y, charGrid)
  if cx then
    self.cx = self.vx + (cx-1)
    self.cy = self.vy + (cy-1)
    self:checkPos()
    self:drawBuffer()
  end
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

local function magiclines(s)
  if s:sub(-1)~="\n" then s=s.."\n" end
  return s:gmatch("(.-)\n")
end

function ce:import(data)
  buffer = {}
  local firstline = true
  for line in magiclines(data) do
    if not(firstline and line == "") then
      table.insert(buffer,line)
    end
    firstline = false
  end
  if not buffer[1] then buffer[1] = "" end
  self.cx, self.cy, self.vx, self.vy = 1,1,1,1
end

function ce:export()
  local data = ""
  for k, line in ipairs(buffer) do
    data = data .. "\n" .. tostring(line)
  end
  return data
end


return ce
