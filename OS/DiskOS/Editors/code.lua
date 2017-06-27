local eapi = select(1,...) --The editor library is provided as an argument

--=Contributing Guide=--
--[[
Try your best to keep your work light, documented and tidy, since this will be the base of other places where text editors exist.

self.cx, self.cy are the position of the brown blinking cursor
* the top-left corner pos is 1, 1
Do not manipulate then directly. Instead, use self:moveCursor(x,y), self:moveCursorX(x) or self:moveCursor(Y).
You don't have to take care if the cursor is out of range when using the methods above.
After changing the cursor position you need to redraw the line, maybe all of them (redraw the buffer).
To find out, check the bufferNeedsRedraw local variable.
if this is true: You have to call self:drawBuffer()
if this is false: It's enough to call self:drawLine()
Lua code: if bufferNeedsRedraw then self:drawBuffer() else self:drawLine() end
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
- Fernando Carmona Varo (Ferk)
- Lucas Henrique (lhsazevedo)
]]

local ce = {} --Code editor

local buffer = {""} --A table containing lines of code

local screenW, screenH = screenSize()
local lume = require("C://Libraries/lume")
local clua = require("C://Libraries/colorize_lua")
local cluacolors = {
text = 7,
keyword = 10,
number = 12,
comment = 13,
str = 12
}

ce.bgc = 5--Background Color
ce.cx, ce.cy = 1, 1 --Cursor Position
ce.fw, ce.fh = fontSize() --The font character size
ce.tw, ce.th = termSize() --The terminal size
ce.th = ce.th-2 --Because of the top and bottom bars
ce.vx, ce.vy = 1,1 --View postions

ce.btimer = 0 --The cursor blink timer
ce.btime = 0.5 --The cursor blink time
ce.bflag = true --The cursor is blinking atm ?

ce.sw, ce.sh = screenSize()
local charGrid = {0,8, ce.sw,ce.sh-16, ce.tw, ce.th}
local bufferNeedsRedraw = false --Flag if the whole buffer requires redrawing

ce.colorize = true --Color lua syntax

--A usefull print function with color support !
function ce:colorPrint(tbl)
  pushColor()
  if type(tbl) == "string" then
    color(cluacolors.text)
    print(tbl,false,true)
  else
    for i=1, #tbl, 2 do
      local col = tbl[i]
      local txt = tbl[i+1]
      color(col)
      print(txt,false,true)--Disable auto newline
    end
  end
  --print("")--A new line
  popColor()
end

--Check the position of the cursor so the view includes it
function ce:checkPos()
  --Y position checking--
  if self.cy > #buffer then self.cy = #buffer end --Passed the end of the file

  if self.cy > self.th + self.vy-1 then --Passed the screen to the bottom
    self.vy = self.cy - (self.th-1)
    bufferNeedsRedraw = true
  elseif self.cy < self.vy then --Passed the screen to the top
    if self.cy < 1 then self.cy = 1 end
    self.vy = self.cy
    bufferNeedsRedraw = true
  end

  --X position checking--
  if buffer[self.cy]:len() < self.cx-1 then self.cx = buffer[self.cy]:len()+1 end --Passed the end of the line !

  if self.cx > self.tw + (self.vx-1) then --Passed the screen to the right
    self.vx = self.cx - (self.tw-1)
    bufferNeedsRedraw = true
  elseif self.cx < self.vx then --Passed the screen to the left
    if self.cx < 1 then self.cx = 1 end
    self.vx = self.cx;
    bufferNeedsRedraw = true
  end

  return bufferNeedsRedraw
end

--- Change cursor X position
function ce:moveCursorX(x)
  self:moveCursor(x, self.cy)
end

--- Change cursor Y position
function ce:moveCursorY(y)
  self:moveCursor(self.cx, y)
end

--- Change cursor X and Y positions
function ce:moveCursor(x, y)
  self.cx = x
  self.cy = y
  self:checkPos()
  self:resetCursorBlink()
end

-- Make the cursor visible and reset the blink timer
function ce:resetCursorBlink()
  ce.btimer = 0
  ce.bflag = true
end

--Draw the cursor blink
function ce:drawBlink()
  if self.cy-self.vy < 0 or self.cy-self.vy > self.th-1 then return end
  if self.bflag then
    rect((self.cx-self.vx+1)*(self.fw+1)-4,(self.cy-self.vy+1)*(self.fh+2)+1, self.fw+1,self.fh, false, 4)
  end
end

--Draw the code on the screen
function ce:drawBuffer()
  local cbuffer = self.colorize and clua(lume.clone(lume.slice(buffer,self.vy,self.vy+self.th-1)),cluacolors) or lume.clone(lume.slice(buffer,self.vy,self.vy+self.th-1))
  rect(0,7,screenW,screenH-8*2+1,false,self.bgc)
  for k, l in ipairs(cbuffer) do
    printCursor(-(self.vx-2)-1,k,-1)
    self:colorPrint(l)
  end
  self:drawBlink()
end

function ce:drawLine()
  if self.cy-self.vy < 0 or self.cy-self.vy > self.th-1 then return end
  local cline = self.colorize and clua({buffer[self.cy]},cluacolors) or {buffer[self.cy]}
  rect(0,(self.cy-self.vy+2)*(self.fh+2)-(self.fh+2), screenW,self.fh+2, false,self.bgc)
  printCursor(-(self.vx-2)-1,(self.cy-self.vy+1),self.bgc)
  self:colorPrint(cline[1])
  self:drawBlink()
end

function ce:drawLineNum()
  eapi:drawBottomBar()
  local linestr = "LINE "..tostring(self.cy).."/"..tostring(#buffer).."  CHAR "..tostring(self.cx-1).."/"..tostring(buffer[self.cy]:len())
  color(eapi.flavorBack) print(linestr,1, self.sh-self.fh-2)
end

function ce:textinput(t)
  buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)..t..buffer[self.cy]:sub(self.cx,-1)
  self:moveCursorX(self.cx + t:len())
  if bufferNeedsRedraw then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

function ce:gotoLineStart()
  self:moveCursorX(1)
  if bufferNeedsRedraw then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

function ce:gotoLineEnd()
  self:moveCursorX(buffer[self.cy]:len()+1)
  if bufferNeedsRedraw then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

-- Will indent the given line based on the previous line
-- returns the amount of leading whitespaces after indentation
function ce:indent(y)
  local wspace = ""
  if y > 1 then -- check the indentation of the previous line
    wspace = buffer[y-1]:match("^ *")
  end
  -- increase indentation if opening a new level in code
  if buffer[y-1]:find('then *$')
    or buffer[y-1]:find('do *$')
    or buffer[y-1]:find("function.*%) *$")
    or buffer[y-1]:find("[[{%(]$")
    then wspace = wspace.."  "
  end
  buffer[y] = buffer[y]:gsub("^ *",wspace)
  return wspace:len()
end

-- Inserts a newline in the given position, splitting the line in two if needed
-- you should execute self:drawBuffer() and self:drawLineNum() after this
function ce:insertNewLineAt(x,y)
  local newLine = buffer[y]:sub(x,-1)
  buffer[y] = buffer[y]:sub(0,x-1)
  if y+1 > #buffer then
    table.insert(buffer,newLine)
  else
    buffer = lume.concat(lume.slice(buffer,0,y),{newLine},lume.slice(buffer,y+1,-1)) --Insert between 2 different lines
  end
end

-- Delete the char from the given coordinates.
-- If out of bounds, it'll merge the line with the previous or next as it suits
-- Returns the coordinates of the deleted character, adjusted if lines were changed
-- and a boolean "true" if other lines changed and redrawing the Buffer is needed
function ce:deleteCharAt(x,y)
  local lineChange = false
  -- adjust "y" if out of bounds, just as failsafe
  if y < 1 then y = 1 elseif y > #buffer then y = #buffer end
  -- newline before the start of line == newline at end of previous line
  if y > 1 and x < 1 then
    y = y-1
    x = buffer[y]:len()+1
  end
  -- join with next line (delete newline) when deleting past the boundaries of the line
  if x > buffer[y]:len() and y < #buffer then
    buffer[y] = buffer[y]..buffer[y+1]
    buffer = lume.concat(lume.slice(buffer,0,y),lume.slice(buffer,y+2,-1))
    lineChange = true
  else
    buffer[y] = buffer[y]:sub(0,x-1) .. buffer[y]:sub(x+1, -1)
  end
  return x,y,lineChange
end

-- Paste the text from the clipboard
function ce:pasteText()
  local text = clipboard()
  text = text:gsub("\t"," ") -- tabs mess up the layout, replace them with spaces
  local firstLine = true
  for line in string.gmatch(text.."\n", "([^\r\n]*)\r?\n") do
    if not firstLine then
      self:insertNewLineAt(self.cx,self.cy)
      self:moveCursor(1, self.cy+1)
    else
      firstLine = false
    end
    self:textinput(line)
  end
  self:checkPos()
  self:drawBuffer()
  self:drawLineNum()
end

-- Last used key, this should be set to the last keymap used from the ce.keymap table
ce.lastKey = ""

ce.keymap = {
  ["return"] = function(self)
    self:insertNewLineAt(self.cx,self.cy)
    local indent = self:indent(self.cy+1)
    self:moveCursor(indent+1, self.cy+1)
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["left"] = function(self)
    self:moveCursorX(self.cx-1)
    if self.cx < 1 then
      if self.cy > 1 then
        self:moveCursor(buffer[self.cy]:len()+1, self.cy-1)
        bufferNeedsRedraw = true
      end
    end
    if bufferNeedsRedraw then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["right"] = function(self)
    self:moveCursorX(self.cx+1)
    if self.cx > buffer[self.cy]:len()+1 then
      if buffer[self.cy+1] then
        self:moveCursor(1, self.cy+1)
        bufferNeedsRedraw = true
      end
    end
    if bufferNeedsRedraw then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["up"] = function(self)
    self:moveCursorY(self.cy-1)
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["down"] = function(self)
    self:moveCursorY(self.cy+1)
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["backspace"] = function(self)
    local lineChange
    local cx
    local cy
    cx, cy, lineChange = self:deleteCharAt(self.cx-1,self.cy)
    self:moveCursor(cx, cy)
    if bufferNeedsRedraw or lineChange then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["delete"] = function(self)
    local lineChange
    local cx
    local cy
    cx, cy, lineChange = self:deleteCharAt(self.cx,self.cy)
    self:moveCursor(cx, cy)
    if bufferNeedsRedraw or lineChange then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["home"] = ce.gotoLineStart,

  ["end"] = ce.gotoLineEnd,

  ["pageup"] = function(self)
    self.vy = self.vy-self.th
    if self.vy > #buffer then self.vy = #buffer end
    if self.vy < 1 then self.vy = 1 end
    self:drawBuffer()
  end,

  ["pagedown"] = function(self)
    self.vy = self.vy+self.th
    if self.vy > #buffer then self.vy = #buffer end
    if self.vy < 1 then self.vy = 1 end
    self:drawBuffer()
  end,

  ["tab"] = function(self)
    -- indent if pressing tab only once, with cursor placed before the first word
    if self.lastKey ~= "tab" and buffer[self.cy]:sub(0,self.cx):find("^ *$") then
        local indent = self:indent(self.cy)
        if indent > 0 then
          self:moveCursorX(indent+1)
          if bufferNeedsRedraw then self:drawBuffer() else self:drawLine() end
          self:drawLineNum()
        else -- insert space anyway if there's no indentation at all
          self:textinput(" ")
        end
    else
      self:textinput(" ")
    end
  end,

  ["ctrl-a"] = ce.gotoStartLine,

  ["ctrl-e"] = ce.gotoEndLine,

  ["ctrl-k"] = function(self)
    local clipbuffer = ""
    if self.cx <= buffer[self.cy]:len() then
      -- cut from cursor position to end of line
      clipbuffer = buffer[self.cy]:sub(self.cx, buffer[self.cy]:len())
      buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)
    elseif self.cy < #buffer then
      -- if at the end of the line, cut the newline
      clipbuffer = "\n"
      self:deleteCharAt(self.cx,self.cy)
    end
    -- consecutive presses will append the content to the clipboard
    if self.lastKey == "ctrl-k" then
      clipbuffer = clipboard()..clipbuffer
    end
    clipboard(clipbuffer)
    self:resetCursorBlink()
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["ctrl-y"] = ce.pasteText,

  ["ctrl-v"] = ce.pasteText,
}

function ce:entered()
  eapi:drawUI()
  cam("translate",0,1)
  self:drawBuffer()
  self:drawLineNum()
end

function ce:leaved()
  cam() --Reset the camera
end

function ce:mousepressed(x, y, button, istouch)
  local cx, cy = whereInGrid(x,y, charGrid)
  if cx then
    self:moveCursor(self.vx + (cx-1), self.vy + (cy-1))
    self:drawBuffer()
    self:drawLineNum()
  end
end

function ce:wheelmoved(x, y)
  self.vy = math.floor(self.vy-y)
  if self.vy > #buffer then self.vy = #buffer end
  if self.vy < 1 then self.vy = 1 end
  self:drawBuffer()
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
  for line in magiclines(data) do
    table.insert(buffer,line)
  end
  if not buffer[1] then buffer[1] = "" end
  self:checkPos()
end

function ce:export()
  local data = ""
  for k, line in ipairs(buffer) do
    if k == 1 then
      data = data .. tostring(line)
    else
      data = data .. "\n" .. tostring(line)
    end
  end
  return data
end


return ce