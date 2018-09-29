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

==Contributors to this file==
(Add your name when contributing to this file)

- technomancy
- Rami Sabbagh (RamiLego4Game)
- Fernando Carmona Varo (Ferk)
- Lucas Henrique (lhs_azevedo)
- trabitboy
- Hachem (hachem2001)
]]

local ce = {} --Code editor

local buffer = {""} --A table containing lines of code

local screenW, screenH = screenSize()
local lume = require("Libraries.lume")
local highlighter = require("Libraries.SyntaxHighlighter")
highlighter:setSyntax("lua")
local highlighterTheme = {
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
highlighter:setTheme(highlighterTheme)

local editorTheme = {
  bg = 5, --Background Color
  cursor = 4 --Cursor Color
}
ce.theme = editorTheme
ce.cx, ce.cy = 1, 1 --Cursor Position
ce.fw, ce.fh = fontSize() --The font character size
ce.tw, ce.th = termSize() --The terminal size
ce.th = ce.th-2 --Because of the top and bottom bars
ce.vx, ce.vy = 1,1 --View postions
--ce.sxs, ce.sys -> Selection start positions, nil when not selecting
--ce.sxe, ce.sye -> Selection end positions, nil when not selecting

ce.mflag = false --Mouse flag

ce.btimer = 0 --The cursor blink timer
ce.btime = 0.5 --The cursor blink time
ce.bflag = true --The cursor is blinking atm ?

ce.stimer = 0 -- The scroll timer when the mouse is dragging up
ce.stime = 0.1 -- The speed of up scrolling when the mouse is dragging up
ce.sflag = 0 -- Direction of scroll. 0 for no scroll, 1 for scroll down, -1 for scroll up.

ce.undoStack={} -- Keep a stack of undo info, each one is {data, state}
ce.redoStack={} -- Keep a stack of redo info, each one is {data, state}

ce.sw, ce.sh = screenSize()
local charGrid = {0,8, ce.sw,ce.sh-16, ce.tw, ce.th}

ce.colorize = true --Color lua syntax

ce.touches = {}
ce.touchesNum = 0
ce.touchscrollx = 0
ce.touchscrolly = 0
ce.touchskipinput = false

--A usefull print function with color support !
function ce:colorPrint(tbl)
  pushColor()
  if type(tbl) == "string" then
    color(highlighterTheme.text)
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
  if self.sxs then return end
  if self.cy-self.vy < 0 or self.cy-self.vy > self.th-1 then return end
  if self.bflag then
    local bx,by,bw,bh = (self.cx-self.vx+1)*(self.fw+1)-4,(self.cy-self.vy+1)*(self.fh+1)+1, self.fw+1,self.fh
    rect(bx,by,bw,bh, false, self.theme.cursor)
    color(5) print(buffer[self.cy]:sub(self.cx,self.cx),bx,by)
  end
end

--Draw the code on the screen
function ce:drawBuffer()
  local vbuffer = lume.slice(buffer,self.vy,self.vy+self.th-1) --Visible buffer
  local cbuffer = self.colorize and highlighter:highlightLines(vbuffer, self.vy) or vbuffer
  rect(0,7,screenW,screenH-8*2+1,false,self.theme.bg)
  for k, l in ipairs(cbuffer) do
    local sxs, sys, sxe, sye = self:getOrderedSelect()
    
    if sxs and self.vy+k-1 >= sys and self.vy+k-1 <= sye then --Selection
      printCursor(-(self.vx-2)-1,k,highlighterTheme.selection)
      local linelen,skip = vbuffer[k]:len(), 0
      
      if self.vy+k-1 == sys then --Selection start
        skip = sxs-1
        printCursor(skip-(self.vx-2)-1)
        linelen = linelen-skip
      end
      
      if self.vy+k-1 == sye then --Selection end
        linelen = sxe - skip
      end
      
      if self.vy+k-1 < sye then --Not the end of the selection
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
    cline, colateral = highlighter:highlightLine(buffer[self.cy], self.cy)
  end
  if not cline then cline = buffer[self.cy] end
  rect(0,(self.cy-self.vy+1)*(self.fh+1), screenW,self.fh+1, false,self.theme.bg)
  printCursor(-(self.vx-2)-1,(self.cy-self.vy+1),self.theme.bg)
  if not colateral then
    self:colorPrint(cline)
  else
    self:drawBuffer()
  end
  self:drawBlink()
end

--Clear the selection just incase
function ce:deselect()
  if self.sxs then self.sxs, self.sys, self.sxe, self.sye = nil, nil, nil, nil; self:drawBuffer() end
end

function ce:getOrderedSelect()
  if self.sxs then
    if self.sye < self.sys then
      return self.sxe, self.sye, self.sxs, self.sys
    elseif self.sye == self.sys and self.sxe<self.sxs then
      return self.sxe, self.sys, self.sxs, self.sye
    else
      return self.sxs, self.sys, self.sxe, self.sye
    end
  else
    return false
  end
end

function ce:drawLineNum()
  eapi:drawBottomBar()
  local linestr = "LINE "..tostring(self.cy).."/"..tostring(#buffer).."  CHAR "..tostring(self.cx-1).."/"..tostring(buffer[self.cy]:len())
  color(eapi.flavorBack) print(linestr,1, self.sh-self.fh-1)
end

function ce:drawIncSearchState()
  eapi:drawBottomBar()
  local linestr = "ISRCH: "
  if self.searchtxt then
   linestr=linestr..self.searchtxt
  end
  color(eapi.flavorBack) print(linestr,1, self.sh-self.fh-3)
end


function ce:searchNextFunction()
 for i,t in ipairs(buffer)
 do
  if  i> self.cy then
   if string.find(t,"function ") then
    self.cy=i
    self:checkPos()
    self:drawBuffer()
    break
   end
  end
 end
end

function ce:searchPreviousFunction()
 highermatch=-1
 for i,t in ipairs(buffer)
 do
  if  i< self.cy then
   if string.find(t,"function ") then
    highermatch=i
   end
  end
 end

 if highermatch>-1 then
  self.cy=highermatch
  self.vy=highermatch
  self:checkPos()
  self:drawBuffer()
 end
 
end



function ce:searchTextAndNavigate(from_line)
 for i,t in ipairs(buffer)
 do
  if from_line~=nil and i> from_line then
   if string.find(t,ce.searchtxt) then
    self.cy=i
  self.vy=i
    self:checkPos()
    self:drawBuffer()
    break
   end
  end
 end

end

function ce:textinput(t)
  if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
  if self.incsearch then
   if self.searchtxt==nil then self.searchtxt="" end
   self.searchtxt=self.searchtxt..t
   -- note on -1 : that way if search is on line , still works
   -- and also ok for ctrl k
   self:searchTextAndNavigate(self.cy-1)
   self:drawIncSearchState()
  else
   self:beginUndoable()
   local delsel
   if self.sxs then self:deleteSelection(); delsel = true end
   buffer[self.cy] = buffer[self.cy]:sub(0,self.cx-1)..t..buffer[self.cy]:sub(self.cx,-1)
   self.cx = self.cx + t:len()
   self:resetCursorBlink()
   if self:checkPos() or delsel then self:drawBuffer() else self:drawLine() end
   self:drawLineNum()
   self:endUndoable()
  end
end

function ce:gotoLineStart()
  self:deselect()
  self.cx = 1
  self:resetCursorBlink()
  if self:checkPos() then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

function ce:gotoLineEnd()
  self:deselect()
  self.cx = buffer[self.cy]:len()+1
  self:resetCursorBlink()
  if self:checkPos() then self:drawBuffer() else self:drawLine() end
  self:drawLineNum()
end

function ce:insertNewLine()
  self:beginUndoable()
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
  self:endUndoable()
end

-- Delete the char from the given coordinates.
-- If out of bounds, it'll merge the line with the previous or next as it suits
-- Returns the coordinates of the deleted character, adjusted if lines were changed
-- and a boolean "true" if other lines changed and redrawing the Buffer is needed
function ce:deleteCharAt(x,y)
  self:beginUndoable()
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
  self:endUndoable()
  return x,y,lineChange
end

--Will delete the current selection
function ce:deleteSelection()
  if not self.sxs then return end --If not selection just return back.
  local sxs, sys, sxe, sye = self:getOrderedSelect()
  
  self:beginUndoable()
  local lnum,slength = sys, sye+1
  while lnum < slength do
    if lnum == sys and lnum == sye then --Single line selection
      buffer[lnum] = buffer[lnum]:sub(1,sxs-1) .. buffer[lnum]:sub(sxe+1,-1)
      lnum = lnum + 1
    elseif lnum == sys then
      buffer[lnum] = buffer[lnum]:sub(1, sxs-1)
      lnum = lnum + 1
    elseif lnum == slength-1 then
      buffer[lnum-1] = buffer[lnum-1] .. buffer[lnum]:sub(sxe+1, -1)
      buffer = lume.concat(lume.slice(buffer,1,lnum-1),lume.slice(buffer,lnum+1,-1))
      slength = slength - 1
    else --Middle line
      buffer = lume.concat(lume.slice(buffer,1,lnum-1),lume.slice(buffer,lnum+1,-1))
      slength = slength - 1
    end
  end
  self.cx, self.cy = sxs, sys
  self:checkPos()
  self:deselect()
  self:drawLineNum()
  self:endUndoable()
end

--Copy selection text (Only if selecting)
function ce:copyText()
  local sxs, sys, sxe, sye = self:getOrderedSelect()
  if sxs then --If there are any selection
    local clipbuffer = {}
    for lnum = sys, sye do
      local line = buffer[lnum]
      
      if lnum == sys and lnum == sye then --Single line selection
        line = line:sub(sxs,sxe)
      elseif lnum == sys then
        line = line:sub(sxs,-1)
      elseif lnum == sye then
        line = line:sub(1, sxe)
      end
      
      table.insert(clipbuffer,line)
    end
    
    local clipdata = table.concat(clipbuffer,"\n")
    clipboard(clipdata)
  end
end

--Cut selection text
function ce:cutText()
  if self.sxs then
    self:copyText()
    self:deleteSelection()
  end
end

-- Paste the text from the clipboard
function ce:pasteText()
  self:beginUndoable()
  if self.sxs then self:deleteSelection() end
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
  self:endUndoable()
end

--Select all text
function ce:selectAll()
  self.sxs, self.sys = 1,1
  self.sye = #buffer
  self.sxe = buffer[self.sye]:len()
  self:drawBuffer()
end

-- Call :beginUndoable() right before doing any modification to the
-- text in the editor. It will capture the current state of the editor's
-- contents (data) and the state of the cursor, selection, etc. (state)
-- so it can be restored later.
-- NOTE: Make sure to balance each call to :beginUndoable() with a call
-- to :endUndoable(). They can nest fine, just don't forget one.
function ce:beginUndoable()
  if self.currentUndo then
    -- we have already stashed the data & state, just track how deep we are
    self.currentUndo.count = self.currentUndo.count + 1
  else
    -- make a new in-progress undo
    self.currentUndo = {
      count=1, -- here is where we track nested begin/endUndoable calls
      data=self:export(),
      state=self:getState()
    }
  end
end

-- Call :endUndoable() after each modification to the text in the editor.
function ce:endUndoable()
  -- We might be inside several nested calls to begin/endUndoable
  self.currentUndo.count = self.currentUndo.count - 1
  -- If this was the last of the nesting
  if self.currentUndo.count == 0 then
    -- then push the undo onto the undo stack.
    table.insert(self.undoStack, {
      self.currentUndo.data,
      self.currentUndo.state
    })
    -- clear the redo stack
    self.redoStack={}
    self.currentUndo=nil
  end
end

-- Perform an undo. This will pop one entry off the undo
-- stack and restore the editor's contents & cursor state.
function ce:undo()
  if #self.undoStack == 0 then
    -- beep?
    return
  end
  -- pull one entry from the undo stack
  local data, state = unpack(table.remove(self.undoStack))
  -- push a new entry onto the redo stack
  table.insert(self.redoStack, {
    self:export(),
    self:getState()
  })
  -- restore the editor contents
  self:import(data)
  -- restore the cursor state
  self:setState(state)
end

-- Perform a redo. This will pop one entry off the redo
-- stack and restore the editor's contents & cursor state.
function ce:redo()
  if #self.redoStack == 0 then
    -- beep?
    return
  end
  -- pull one entry from the redo stack
  local data, state = unpack(table.remove(self.redoStack))
  -- push a new entry onto the undo stack
  table.insert(self.undoStack, {
    self:export(),
    self:getState()
  })
  -- restore the editor contents
  self:import(data)
  -- restore the cursor state
  self:setState(state)
end

-- Get the state of the cursor, selection, etc.
-- This is used for the undo/redo feature.
function ce:getState()
  return {
    cx=self.cx,
    cy=self.cy,
    sxs=self.sxs,
    sys=self.sys,
    sxe=self.sxe,
    sye=self.sye,
  }
end

-- Set the state of the cursor, selection, etc.
-- This is used for the undo/redo feature.
function ce:setState(state)
  self.cx=state.cx
  self.cy=state.cy
  self.sxs=state.sxs
  self.sys=state.sys
  self.sxe=state.sxe
  self.sye=state.sye
  self:checkPos()
  self:drawBuffer()
  self:drawLineNum()
end

-- Last used key, this should be set to the last keymap used from the ce.keymap table
ce.lastKey = ""

ce.keymap = {
  ["return"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    if self.sxs then ce:deleteSelection() end
    ce:insertNewLine()
  end,

  ["left"] = function(self)
    self:deselect()
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

  ["right"] = function(self)
    self:deselect()
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
  ["shift-up"] = function(self)
    --in case we want to reduce shift selection
    if self.cy==1 then
     --we stay in buffer
     return
    end
    if self.sxs then
     --there is an existing selection to update
      self.cy=self.cy-1
      self:checkPos()
      self.sye=self.cy
      self.sxe=math.min(self.cx, #buffer[self.cy])
    else
      self.sxs = self.cx
      self.sys = self.cy
      self.cy=self.cy-1
      self:checkPos()
      self.sye=self.cy
      self.sxe=math.min(self.cx, #buffer[self.cy])
    end
    self:drawBuffer()
    self:drawLineNum()
  end,
  
  ["alt-up"] = function(self)
   self:searchPreviousFunction()
  end,
  
  ["alt-down"] = function(self)
   self:searchNextFunction()
  end,
  
  ["shift-down"] = function(self)
    --last line check, we do not go further than buffer
    if #buffer == self.cy then
      return
    end
    
    if self.sxs then
      self.cy=self.cy+1
      self:checkPos()
      self.sye = self.cy
      self.sxe = math.min(self.cx, #buffer[self.cy])
    else
      self.sxs = self.cx
      self.sys = self.cy
      self.cy=self.cy+1
      self:checkPos()
      self.sye = self.cy
      self.sxe = math.min(self.cx, #buffer[self.cy])
    end
    self:drawBuffer()
    self:drawLineNum()
  end,
  ["shift-right"] = function(self)
  
    --last line check, we do not go further than buffer
    if #buffer == self.cy and self.cx == #buffer[self.cy] then
      return
    end
    local originalcx, originalcy = self.cx, self.cy
    self.cx = self.cx + 1
    
    if self.cx > buffer[self.cy]:len()+1 then
      if buffer[self.cy+1] then
        self.cy = self.cy + 1
        self.cx = 1
      end
    end
    self:checkPos()
    
    if self.sxs then
      self.sye = self.cy
      self.sxe = math.min(self.cx, #buffer[self.cy])
    else
      self.sxs = originalcx
      self.sys = originalcy
      self.sye = self.cy
      self.sxe = math.min(self.cx, #buffer[self.cy])
    end
    
    self:drawBuffer()
    self:drawLineNum()
  end,
  
  ["shift-left"] = function(self)
    --last line check, we do not go further than buffer
    if 0 == self.cy and self.cx <= 1 then
      return
    end
    local originalcx, originalcy = self.cx, self.cy
    self.cx = self.cx - 1
    
    if self.cx < 1 then
      if self.cy > 1 then
        self.cy = self.cy -1
        self.cx = buffer[self.cy]:len()+1
      end
    end
    self:checkPos()
    
    if self.sxs then
      self.sye = self.cy
      self.sxe = math.min(self.cx, #buffer[self.cy])
    else
      self.sxs = originalcx
      self.sys = originalcy
      self.sye = self.cy
      self.sxe = math.min(self.cx, #buffer[self.cy])
    end
    
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["up"] = function(self)
    self:deselect()
    self.cy = self.cy -1
    self:resetCursorBlink()
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end,
  
  ["down"] = function(self)
    self:deselect()
    self.cy = self.cy +1
    self:resetCursorBlink()
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["backspace"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    if self.sxs then self:deleteSelection() return end
    if self.cx == 1 and self.cy == 1 then return end
    local lineChange
    self.cx, self.cy, lineChange = self:deleteCharAt(self.cx-1,self.cy)
    self:resetCursorBlink()
    if self:checkPos() or lineChange then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["delete"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    if self.sxs then self:deleteSelection() return end
    local lineChange
    self.cx, self.cy, lineChange = self:deleteCharAt(self.cx,self.cy)
    self:resetCursorBlink()
    if self:checkPos() or lineChange then self:drawBuffer() else self:drawLine() end
    self:drawLineNum()
  end,

  ["home"] = ce.gotoLineStart,

  ["end"] = ce.gotoLineEnd,

  ["pageup"] = function(self)
    self.vy = self.vy-self.th
    self.cy = self.cy-self.th
    
    if self.vy < 1 then self.vy = 1 end
    if self.cy < 1 then self.cy = 1 end
    
    self:resetCursorBlink()
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["pagedown"] = function(self)
    self.vy = self.vy+self.th
    self.cy = self.cy+self.th
  
    if self.vy > #buffer then self.vy = #buffer end
    if self.cy > #buffer then self.cy = #buffer end
    self:resetCursorBlink()
    self:drawBuffer()
    self:drawLineNum()
  end,

  ["tab"] = function(self)
    self:textinput(" ")
  end,
  ["ctrl-i"] = function(self)
   if self.incsearch==nil or self.incsearch==false then
    self.incsearch=true
  self:drawIncSearchState()
   else
    self.incsearch=false
  self.searchtxt=""
    self:drawLineNum()
   end
  end,
  ["ctrl-k"] = function(self)
   if self.incsearch==true then
  self:searchTextAndNavigate(self.cy)
   end
  end,
  ["ctrl-x"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    ce:cutText()
  end,
  
  ["ctrl-c"] = ce.copyText,

  ["ctrl-v"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    ce:pasteText()
  end,
  
  ["ctrl-a"] = ce.selectAll,
  
  ["ctrl-z"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    ce:undo()
  end,

  ["shift-ctrl-z"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    ce:redo()
  end,
  
  ["ctrl-y"] = function(self)
    if self.readonly then _systemMessage("The file is readonly !",1,9,4) return end
    ce:redo()
  end,
}

ce.keymap["alt-backspace"] = ce.keymap["delete"]

function ce:entered()
  eapi:drawUI()
  cam("translate",0,1)
  self:drawBuffer()
  self:drawLineNum()
  ce.touches = {}
  ce.touchesNum = 0
  ce.touchscrollx = 0
  ce.touchscrolly = 0
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
    
    if self.sxs then self.sxs,self.sys,self.sxe,self.sye = false,false,false,false end --End selection
    
    self:checkPos()
    self:drawBuffer()
    self:drawLineNum()
  end
end

function ce:mousemoved(x,y,dx,dy,it)
  if istouch or not self.mflag then return end
  local cx, cy = whereInGrid(x,y, charGrid)
  local ocx, ocy = cx, cy
  if cx then
    cx, cy = self:clampPos(cx+self.vx-1,cy+self.vy-1)
    self.bflag = false --Disable blinking
    if not self.sxs then --Start the selection
      self.sxs, self.sys = cx, cy
      self.sxe, self.sye = self.cx, self.cy
      -- Note: the ordered selection is given by ce:getOrderedSelect()
      -- This is used to avoid extra overhead.
    else
      self.sxe, self.sye = cx, cy
      if y > self.sh*(0.9) then
        self.sflag = 1
      elseif y < self.sh*0.1 then
        self.sflag = -1
      else
        self.sflag = 0
      end
    end
    
    self:drawBuffer()
  elseif self.sxs then --Top bar
    self.bflag = false --Disable blinking
  end
  if y > self.sh*(0.9) then
    self.sflag = 1
  elseif y < self.sh*0.1 then
    self.sflag = -1
  else
    self.sflag = 0
  end
end

function ce:mousereleased(x,y,b,it)
  self.mflag = false
  self.sflag = 0
end

function ce:wheelmoved(x, y)
  self.vy = math.floor(self.vy-y)
  if self.vy > #buffer then self.vy = #buffer end
  if self.vy < 1 then self.vy = 1 end
  self.vx = math.floor(self.vx+x)
  if self.vx < 1 then self.vx = 1 end
  self:drawBuffer()
end

function ce:touchpressed(id,x,y,dx,dy,p)
  table.insert(self.touches,id)
  self.touchesNum = self.touchesNum + 1
end

function ce:touchmoved(id,x,y,dx,dy,p)
  if self.touchesNum > 1 then
    textinput(false) self.touchskipinput = true
    self.touchscrollx = self.touchscrollx - dx
    self.touchscrolly = self.touchscrolly + dy
    
    if self.touchscrollx >= 14 or self.touchscrollx <= -14 then
      ce:wheelmoved(self.touchscrollx/14,0)
      self.touchscrollx = self.touchscrollx - math.floor(self.touchscrollx/14)
    end
    
    if self.touchscrolly >= 14 or self.touchscrolly <= -14 then
      ce:wheelmoved(0,self.touchscrolly/14)
      self.touchscrolly = self.touchscrolly - math.floor(self.touchscrolly/14)
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
      self.btimer = self.btimer % self.btime
      self.bflag = not self.bflag
      self:drawLine() --Redraw the current line
    end
  elseif self.sflag~=0 then -- if selecting with the mouse and scrolling up/down
    self.stimer = self.stimer + dt
    if self.stimer > self.stime then
      self.stimer = self.stimer % self.stime
      self.vy = self.vy + self.sflag
      if self.vy <= 0 then
        self.vy = 1
      elseif self.vy > #buffer then
        self.vy = #buffer
      end
      
      self:drawBuffer()
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

function ce:decode(data)
  self:import(BinUtils.binToCode(data))
end

function ce:export()
  return table.concat(buffer, "\n")
end

function ce:encode()
  return BinUtils.codeToBin(self:export())
end

return ce
