local cedit = {}

local colorize = require("libraries.colorize_lua")

cedit.colors = {
text = _GetColor(8),
keyword = _GetColor(11),--15),
number = _GetColor(13),--13),
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

function cedit:export()
  local code = ""
  for line,text in ipairs(self.codebuffer) do
    code = code..text.."\n"
  end
  return code
end

local function magiclines(s)
  if s:sub(-1)~="\n" then s=s.."\n" end
  return s:gmatch("(.-)\n")
end

function cedit:load(code)
  self.codebuffer, self.topLine, self.cursorX, self.cursorY = {}, 0, 1, 1
  if not code then self.codebuffer[1] = "" return self end
  local code = code
  for line in magiclines(code) do
    table.insert(self.codebuffer,line)
  end
  return self
end

function cedit:_switch()
  
end

function cedit:_redraw()
  api.rect(1,9,192,128-16,6) api.color(7)
  local tocolor = {}
  for i=self.topLine+1,self.topLine+self.lineLimit do
    if self.codebuffer[i] then table.insert(tocolor,self.codebuffer[i]) end
  end
  local colored = colorize(tocolor,self.colors)
  api.color(8)
  for line,text in ipairs(colored) do
    api.print_grid(text,1,line+1)
  end
  
  api.rect(1,128-7,192,8,10)
  api.color(5)
  api.print("LINE "..self.topLine+self.cursorY.."/"..#self.codebuffer,2,128-5)
  
  --[[for i=self.topLine+1,self.topLine+self.lineLimit do
    if self.codebuffer[i] then api.print_grid(self.codebuffer[i],1,(i-self.topLine)+1) end
  end]]
end

function cedit:_update(dt)
  blinktimer = blinktimer+dt if blinktimer > blinktime then blinktimer = blinktimer - blinktime  blinkstate = not blinkstate end
  local curlen = self.codebuffer[self.topLine+self.cursorY]:len()
  if blinkstate then api.rect((self.cursorX-1)*4+2,(self.cursorY)*8+2,4,5,5) else self:_redraw() end
end

function cedit:_mmove(x,y,dx,dy,it,iw)
  if math.abs(y) > 5 then return end --Dead mouse wheen strike
  if math.abs(x) > 5 then return end --Dead mouse wheen strike
  if y > 0 then
    self:_kpress("up",0,false)
  elseif y < 0 then
    self:_kpress("down",0,false)
  end
  
  if x > 0 then
    self:_kpress("right",0,false) --Maybe ? or inverted..
  elseif x < 0 then
    self:_kpress("left",0,false)
  end
end

cedit.keymap = {
  ["return"] = function(self)
    -- check if the cursor is at the last line
    if self.cursorY == self.lineLimit then
      self.topLine = self.topLine+1
    else
      self.cursorY = self.cursorY+1
    end

    for i=#self.codebuffer, self.cursorY+self.topLine, -1 do
      self.codebuffer[i+1] = self.codebuffer[i]
    end--Shift down the code

    local offset = self.cursorY+self.topLine
    self.codebuffer[offset] = self.codebuffer[offset-1]:sub(self.cursorX,-1)
    self.codebuffer[offset-1] = self.codebuffer[offset-1]:sub(0,self.cursorX-1)

    -- self.codebuffer[self.cursorY+self.topLine] = "" --Insert a new empty line
    -- Set the cursorX to 1 (since it's an empty line), also reset the
    -- blinkstate&timer to force the cursor to blink on
    self.cursorX, blinktimer, blinkstate = 1, 0, true
  end,

  backspace = function(self)
    local offset = self.cursorY+self.topLine
    if self.codebuffer[offset] == "" then
      if self.cursorY ~= 1 then
         --Remove the line so the table size stays correct
        table.remove(self.codebuffer,offset)
        if self.cursorY == 1 then
         self.topLine = self.topLine-1
         if self.topLine < 1 then self.topline=0 end
        else
         self.cursorY = self.cursorY-1
        end
        self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1
      end
    else
      if self.cursorX > 1 then
        self.codebuffer[offset] =
          self.codebuffer[offset]:sub(0,self.cursorX-2) ..
          self.codebuffer[offset]:sub(self.cursorX,-1)
        self.cursorX = self.cursorX-1
      --[[else
        self.codebuffer[offset-1] = self.codebuffer[offset-1]..(self.codebuffer[offset] or "")
        for i=offset, #self.codebuffer do self.codebuffer[i] = self.codebuffer[i+1] end--Shift up the code
        table.remove(self.codebuffer,#self.codebuffer) --Drop The last line (because it got duplicated)
        self.cursorY = self.cursorY-1
        if self.cursorY < 1 then if self.topLine > 0 then self.topLine = self.topLine -1 end self.cursorY = 1 end
        self.cursorX = self.codebuffer[offset-1]:len()+1  MUST SETUP LINE LENGTH SYSTEM FIRST]]
      end
    end
    blinktimer, blinkstate = 0, true
  end,

  up = function(self)
    self.cursorY = self.cursorY-1
    if self.cursorY < 1 then if self.topLine > 0 then self.topLine = self.topLine -1 end self.cursorY = 1 end
    if ir then self.cursorX = lastCursorX else lastCursorX = self.cursorX end
    if self.cursorX > self.codebuffer[self.cursorY+self.topLine]:len()+1 then self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1 end
    blinktimer, blinkstate = 0, true
  end,

  down = function(self)
    blinktimer, blinkstate = 0, true
    if self.cursorY+self.topLine == #self.codebuffer then return end
    if self.cursorY == self.lineLimit then
      self.topLine = self.topLine+1
    else
      self.cursorY = self.cursorY+1
    end
    if ir then self.cursorX = lastCursorX else lastCursorX = self.cursorX end
    if self.cursorX > self.codebuffer[self.cursorY+self.topLine]:len()+1 then self.cursorX = self.codebuffer[self.cursorY+self.topLine]:len()+1 end
  end,

  left = function(self)
    local lineNum = self.cursorY+self.topLine
    self.cursorX = self.cursorX - 1
    if self.cursorX < 1 and lineNum > 1 then
      self.keymap.up(self)
      self.keymap["end"](self)
    elseif self.cursorX < 1 then
      self.cursorX = 1
    end
    blinktimer, blinkstate = 0, true
  end,

  right = function(self)
    local lineNum = self.cursorY+self.topLine
    self.cursorX = self.cursorX + 1
    if self.cursorX > #self.codebuffer[lineNum] then
      if lineNum < #self.codebuffer then
        self.keymap.down(self)
        self.keymap.home(self)
      else
        self.cursorX = #self.codebuffer[lineNum] + 1
      end
    end
    blinktimer, blinkstate = 0, true
  end,

  home = function(self)
   self.cursorX = 1
  end,

  ["end"] = function(self)
    self.cursorX = #self.codebuffer[self.topLine+self.cursorY] + 1
  end
}

function cedit:_krelease(k,sc)
  lastCursorX = 1
end

function cedit:_tinput(t)
  if t == "\\" then return end --This thing is so bad, so GO AWAY
  blinktimer, blinkstate = 0, true
  if self.codebuffer[self.cursorY+self.topLine]:len() == 46 then return end
  self.codebuffer[self.cursorY+self.topLine] = self.codebuffer[self.cursorY+self.topLine]:sub(0,self.cursorX-1)..t..self.codebuffer[self.cursorY+self.topLine]:sub(self.cursorX,-1)--self.codebuffer[self.cursorY+self.topLine]..t
  self.cursorX = self.cursorX+1
  self:_redraw()
end

function cedit:_tpress()
  --This means the user is using a touch device
  self.lineLimit = 7
  api.showkeyboard(true)
end

return cedit
