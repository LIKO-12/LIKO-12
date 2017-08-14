local eapi = select(1,...) --The editor library is provided as an argument

--=Contributing Guide=--
--[[
Try your best to keep your work light, documented and tidy, since this will be the base of other places where text editors exist.

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
- Fernando Carmona Varo (Ferk)
- Lucas Henrique (lhs_azevedo)
]]

local ce = {} --Code editor

local buffer = {""} --A table containing lines of code

local screenW, screenH = screenSize()
local lume = require("Libraries/lume")
local syntax = require("Libraries/syntax")
syntax:setSyntax('lua')
local syntaxTheme = {
  text = 7,
  keyword = 10,
  number = 12,
  comment = 13,
  string = 11,
  api = 14,
  callback = 15,
  selection = 6,
  escape = 12
}
syntax:setTheme(syntaxTheme)

ce.bgc = 5--Background Color
ce.cx, ce.cy = 1, 1 --Cursor Position
ce.fw, ce.fh = fontSize() --The font character size
ce.tw, ce.th = termSize() --The terminal size
ce.th = ce.th-2 --Because of the top and bottom bars
ce.vx, ce.vy = 1,1 --View postions
--ce.sxs, ce.sys -> Selection start positions, nil when not selecting
--ce.sxe, ce.sye -> Selection start positions, nil when not selecting
--ce.sdir -> Selection direction (true for up, false for down), nil when not selecting
ce.mflag = false --Mouse flag

ce.btimer = 0 --The cursor blink timer
ce.btime = 0.5 --The cursor blink time
ce.bflag = true --The cursor is blinking atm ?

ce.sw, ce.sh = screenSize()
local charGrid = {0,8, ce.sw,ce.sh-16, ce.tw, ce.th}

ce.colorize = true --Color lua syntax

ce.touches = {}
ce.touchesNum = 0
ce.touchscroll = 0
ce.touchskipinput = false

--A usefull print function with color support !
function ce:colorPrint(tbl)
  pushColor()
  if type(tbl) == "string" then
    color(syntaxTheme.text)
    print(tbl,false,true)
  else
    for i=1, #tbl, 2 do
      local col = tbl[i]
      local txt = tbl[i+1]
      color(col)
      print(txt,false,true)--Disable auto newline
    end
  end
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

function ce:clampPos(x,y)
  --Y position checking--
  if y > #buffer then y = #buffer end --Passed the end of the file

  if y < self.vy then --Passed the screen to the top
    if y < 1 then y = 1 end
  end
  
  --X position checking--
  if buffer[y]:len() < x-1 then x = buffer[y]:len()+1 end --Passed the end of the line !

  if x < self.vx then --Passed the screen to the left
    if x < 1 then x = 1 end
  end
  
  return x, y
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
  local vbuffer = lume.clone(lume.slice(buffer,self.vy,self.vy+self.th-1)) --Visible buffer
  local cbuffer = self.colorize and syntax:highlightLines(vbuffer, self.vy) or vbuffer
  rect(0,7,screenW,screenH-8*2+1,false,self.bgc)
  for k, l in ipairs(cbuffer) do
    if self.sxs and self.vy+k-1 >= self.sys and self.vy+k-1 <= self.sye then --Selection
      printCursor(-(self.vx-2)-1,k,syntaxTheme.selection)
      local linelen,skip = vbuffer[k]:len(), 0
      if self.vy+k-1 == self.sys then --Selection start
        skip = self.sxs-1
        printCursor(skip-(self.vx-2)-1)
        linelen = linelen-skip
      end
      
      if self.vy+k-1 == self.sye then --Selection end
        linelen = self.sxe - skip
      end
      
      if self.vy+k-1 < self.sye then --Not the end of the selection
        linelen = linelen + 1
      end
      
      print(string.rep(" ",linelen),false,true)
    end
    printCursor(-(self.vx-2)-1,k,-1)
    self:colorPrint(l)
  end
  self:drawBlink()
end

function ce:drawLine()
  if self.cy-self.vy < 0 or self.cy-self.vy > self.th-1 then return end
  local cline, colateral
  if self.colorize then
    cline, colateral = syntax:highlightLine(buffer[self.cy], self.cy)
  end
  if not cline then cline = buffer[self.cy] end
  rect(0,(self.cy-self.vy+2)*(self.fh+2)-(self.fh+2), screenW,self.fh+2, false,self.bgc)
  printCursor(-(self.vx-2)-1,(self.cy-self.vy+1),self.bgc)
  if not colateral then
    self:colorPrint(cline)
  else
    self:drawBuffer()
  end
  self:drawBlink()
end

function ce:drawLineNum()
  eapi:drawBottomBar()
  local linestr = "LINE "..tostring(self.cy).."/"..tostring(#buffer).."  CHAR "..tostring(self.cx-1).."/"..tostring(buffer[self.cy]:len())
  color(eapi.flavorBack) print(linestr,1, self.sh-self.fh-2)
end

function ce:textinput(t)
  buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)..t..buffer[self.cy]:sub(self.cx,-1)
  self.cx = self.cx + t:len()
  self:resetCursorBlink()
  if self:checkPos() then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

function ce:gotoLineStart()
  self.cx = 1
  self:resetCursorBlink()
  if self:checkPos() then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

function ce:gotoLineEnd()
  self.cx = buffer[self.cy]:len()+1
  self:resetCursorBlink()
  if self:checkPos() then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

function ce:insertNewLine()
  local newLine = buffer[self.cy]:sub(self.cx,-1)
  buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)
  local snum = string.find(buffer[self.cy].."a","%S") --Number of spaces
  snum = snum and snum-1 or 0
  newLine = string.rep(" ",snum)..newLine
  self.cx, self.cy = snum+1, self.cy+1
  if self.cy > #buffer then
    table.insert(buffer,newLine)
  else
    buffer = lume.concat(lume.slice(buffer,0,self.cy-1),{newLine},lume.slice(buffer,self.cy,-1)) --Insert between 2 different lines
  end
  self:resetCursorBlink()
  self:checkPos()
  self:drawBuffer()
  self:drawLineNum()
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
      self:insertNewLine() self.cx=1
    else
      firstLine = false
    end
    self:textinput(line)
  end
  if self:checkPos() then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

-- Last used key, this should be set to the last keymap used from the ce.keymap table
ce.lastKey = ""

ce.keymap = {
  ["sc_return"] = ce.insertNewLine,

  ["sc_left"] = function(self)
    local flag = false
    self.cx = self.cx -1
    if self.cx < 1 then
      if self.cy > 1 then
        self.cy = self.cy -1
        self.cx = buffer[self.cy]:len()+1
        flag = true
      end
    end
    self:resetCursorBlink()
    if self:checkPos() or flag then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["sc_right"] = function(self)
    local flag = false
    self.cx = self.cx +1
    if self.cx > buffer[self.cy]:len()+1 then
      if buffer[self.cy+1] then
        self.cy = self.cy +1
        self.cx = 1
        flag = true
      end
    end
    self:resetCursorBlink()
    if self:checkPos() or flag then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["sc_up"] = function(self)
    self.cy = self.cy -1
    self:resetCursorBlink()
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["sc_down"] = function(self)
    self.cy = self.cy +1
    self:resetCursorBlink()
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["sc_backspace"] = function(self)
    if self.cx == 1 and self.cy == 1 then return end
    local lineChange
    self.cx, self.cy, lineChange = self:deleteCharAt(self.cx-1,self.cy)
    self:resetCursorBlink()
    if self:checkPos() or lineChange then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["sc_delete"] = function(self)
    local lineChange
    self.cx, self.cy, lineChange = self:deleteCharAt(self.cx,self.cy)
    self:resetCursorBlink()
    if self:checkPos() or lineChange then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["sc_home"] = ce.gotoLineStart,

  ["sc_end"] = ce.gotoLineEnd,

  ["sc_pageup"] = function(self)
    self.vy = self.vy-self.th
    if self.vy > #buffer then self.vy = #buffer end
    if self.vy < 1 then self.vy = 1 end
    self:resetCursorBlink()
    self:drawBuffer()
  end,

  ["sc_pagedown"] = function(self)
    self.vy = self.vy+self.th
    if self.vy > #buffer then self.vy = #buffer end
    if self.vy < 1 then self.vy = 1 end
    self:resetCursorBlink()
    self:drawBuffer()
  end,

  ["sc_tab"] = function(self)
    self:textinput(" ")
  end,

  ["sc_ctrl-a"] = ce.gotoLineStart,

  ["sc_ctrl-e"] = ce.gotoLineEnd,

  ["sc_ctrl-k"] = function(self)
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
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["sc_ctrl-y"] = ce.pasteText,

  ["sc_ctrl-v"] = ce.pasteText,
}


function ce:entered()
  eapi:drawUI()
  cam("translate",0,1)
  self:drawBuffer()
  self:drawLineNum()
  ce.touches = {}
  ce.touchesNum = 0
  ce.touchscroll = 0
  ce.touchskipinput = false
end

function ce:leaved()
  cam() --Reset the camera
end

function ce:mousepressed(x, y, button, istouch)
  if istouch then return end
  local cx, cy = whereInGrid(x,y, charGrid)
  if cx then
    self.mflag = true
    
    self.cx = self.vx + (cx-1)
    self.cy = self.vy + (cy-1)
    
    if self.sxs then self.sxs,self.sys,self.sxe,self.sye,self.sdir = false,false,false,false,false end --End selection
    
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end
end

function ce:mousemoved(x,y,dx,dy,it)
  if istouch or not self.mflag then return end
  local cx, cy = whereInGrid(x,y, charGrid)
  if cx then
    cx, cy = self:clampPos(cx+self.vx-1,cy+self.vy-1)
    self.bflag = false --Disable blinking
    if not self.sxs then --Start the selection
      if self.cy > cy then
        self.sdir = true --UP
        self.sxs, self.sys = cx, cy
        self.sxe, self.sye = self.cx, self.cy
      else
        self.sdir = false --DOWN
        self.sxs, self.sys = self.cx, self.cy
        self.sxe, self.sye = cx, cy
      end
    else
      local function switch(s)
        if (s and not self.sdir) then
          self.sxe, self.sye = self.sxs, self.sys
        elseif (self.sdir and not s) then
          self.sxs, self.sys = self.sxe, self.sye
        end
        self.sdir = s
      end
      
      if self.sdir then
        if cy == self.sye and cx > self.sxe then
          switch(false)
        elseif cy > self.sye then
          switch(false)
        end
      else
        if cy == self.sys and cx < self.sxs then
          switch(true)
        elseif cy < self.sys then
          switch(true)
        end
      end
      
      if self.sdir then
        self.sxs, self.sys = cx, cy
      else
        self.sxe, self.sye = cx, cy
      end
    end
    
    self:drawBuffer()
  elseif x > 8 and self.sxs then --Bottom bar
    self.bflag = false --Disable blinking
    
  elseif self.sxs then --Top bar
    self.bflag = false --Disable blinking
    
  end
end

function ce:mousereleased(x,y,b,it)
  self.mflag = false
end

function ce:wheelmoved(x, y)
  self.vy = math.floor(self.vy-y)
  if self.vy > #buffer then self.vy = #buffer end
  if self.vy < 1 then self.vy = 1 end
  self:drawBuffer()
end

function ce:touchpressed(id,x,y,dx,dy,p)
  table.insert(self.touches,id)
  self.touchesNum = self.touchesNum + 1
end

function ce:touchmoved(id,x,y,dx,dy,p)
  if self.touchesNum > 1 then
    textinput(false) self.touchskipinput = true
    self.touchscroll = self.touchscroll + dy
    if self.touchscroll >= 14 or self.touchscroll <= -14 then
      ce:wheelmoved(0,self.touchscroll/14)
      self.touchscroll = self.touchscroll - math.floor(self.touchscroll/14)
    end
  end
end

function ce:touchreleased(id,x,y,dx,dy,p)
  table.remove(self.touches,lume.find(self.touches,id))
  self.touchesNum = self.touchesNum - 1
  if self.touchesNum == 0 then
    if self.touchskipinput then
      self.touchskipinput = false
    else
      textinput(true)
      local cx, cy = whereInGrid(x,y, charGrid)
      if cx then
        self.cx = self.vx + (cx-1)
        self.cy = self.vy + (cy-1)
        self:checkPos()
        self:drawBuffer()
        self:drawLineNum()
      end
    end
  end
end

function ce:update(dt)
  --Blink timer
  if not self.sxs then --If not selecting
    self.btimer = self.btimer + dt
    if self.btimer >= self.btime then
      self.btimer = self.btimer - self.btime
      self.bflag = not self.bflag
      self:drawLine() --Redraw the current line
    end
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