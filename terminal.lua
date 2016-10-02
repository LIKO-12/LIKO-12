local lume = require("libraries.lume")
local Terminal = {}

Terminal.blinktime = 0.5
Terminal.blinktimer = 0
Terminal.blinkstate = false

Terminal.textbuffer = {}
Terminal.textcolors = {}
Terminal.linesLimit = 14
Terminal.lengthLimit = 43
Terminal.currentLine = 1

Terminal.rootDir = "/"

function Terminal:wrap_string(str,ml)
  local ml = ml or (Terminal.lengthLimit-5)-(self.rootDir:len()+1)
  local lt = api.floor(str:len()/ml+0.99)
  if lt <= 1 then return {str} end
  local t = {}
  for i = 1, lt+1 do
    table.insert(t,str:sub(0,ml-1))
    str=str:sub(ml,-1)
  end
  return t
end

function Terminal:tout(text,col,skipnl,pathLen)
  local text = text or ""
  local length = pathLen and (Terminal.lengthLimit-5)-(self.rootDir:len()+1) or Terminal.lengthLimit
  for _,line in ipairs(lume.split(text, "\n")) do
    for _,wrapped_line in ipairs(self:wrap_string(line,length)) do
      self:tout_line(wrapped_line,col,skipnl)
    end
  end
end

function Terminal:tout_line(text,col,skipnl)
  self.textcolors[self.currentLine] = col or self.textcolors[self.currentLine]
  if skipnl then
    self.textbuffer[self.currentLine] = self.textbuffer[self.currentLine]..(text or "")
    if self.textbuffer[self.currentLine]:len() >= self.lengthLimit then self.textbuffer[self.currentLine] = self.textbuffer[self.currentLine]:sub(0,self.lengthLimit) end
  else
    self.textbuffer[self.currentLine] = self.textbuffer[self.currentLine]..(text or "")
    if self.textbuffer[self.currentLine]:len() >= self.lengthLimit then self.textbuffer[self.currentLine] = self.textbuffer[self.currentLine]:sub(0,self.lengthLimit) end
    if self.currentLine == self.linesLimit then
      for i=2,self.linesLimit do self.textbuffer[i-1] = self.textbuffer[i] end --Shiftup all the text
      for i=2,self.linesLimit do self.textcolors[i-1] = self.textcolors[i] end
      self.textbuffer[self.currentLine] = "" --Add a new line
    else
      self.currentLine = self.currentLine + 1
    end
  end
  self:_redraw()
end
function Terminal:setLine(l) self.currentLine = api.floor(l or 1) if self.currentLine > 20 then self.currentLine = 20 elseif self.currentLine < 1 then self.currentLine = 1 end end

function Terminal:splitCommand(str)
  local t = {}
  for val in str:gmatch("%S+") do
    if not t[0] then t[0] = val else table.insert(t, val) end
  end
  return t
end

function Terminal:_init()
  for i=1,self.linesLimit do table.insert(self.textbuffer,"") end --Clean the framebuffer
  for i=1,self.linesLimit do table.insert(self.textcolors,8) end
  api.keyrepeat(true)
  self:tout("-[[liko12]]-")
  self:tout(_LK12VER,_LK12VERC)
  self:tout()
  self:tout("A PICO-8 CLONE WITH EXTRA ABILITIES",7)
  self:tout("TYPE HELP FOR HELP",10)
  self:tout(self.rootDir.."> ",8,true)
  
end

function Terminal:_update(dt)
  self.blinktimer = self.blinktimer+dt if self.blinktimer > self.blinktime then self.blinktimer = self.blinktimer - self.blinktime  self.blinkstate = not self.blinkstate end
  local curlen = self.textbuffer[self.currentLine]:len()
  api.color(self.blinkstate and 5 or 1)
  api.rect(curlen > 0 and ((curlen)*4+8+3) or 10,(self.currentLine)*8+2,4,5)
end

function Terminal:_redraw()
  api.clear(1)
  for line,text in ipairs(self.textbuffer) do
    api.color(self.textcolors[line])
    if text == "-[[liko12]]-" then --THE SECRET PHASE
      api.SpriteGroup(49,9,line*8,6,1,1,1,api.EditorSheet)
    else
      api.print_grid(text,2,line+1)
    end
  end
end

function Terminal:_kpress(k,sc,ir)
  if k == "return" then
    self:tout()
    local splitted = self:splitCommand(self.textbuffer[self.currentLine-1])
    local CMDFunc = require("terminal_commands")[string.lower(splitted[1] or "")]
    if CMDFunc then
      CMDFunc(unpack(splitted))
    elseif splitted[1] then
      self:tout("UNKNOWN COMMAND '"..splitted[1].."' !",15)
    end
    self:tout(self.rootDir.."> ",8,true,true)
  end
  if k == "backspace" then self.textbuffer[self.currentLine] = self.textbuffer[self.currentLine]:sub(0,-2) self:_redraw() end
end

function Terminal:_tinput(t)
  if t == "\\" then return end --This thing is so bad, so GO AWAY
  if self.textbuffer[self.currentLine]:len() < self.lengthLimit then self:tout(t,8,true) end
end

function Terminal:_tpress()
  --This means the user is using a touch device
  self.linesLimit = 7
  api.showkeyboard(true)
end

function Terminal:setRoot(path)
  self.rootDir = path or "/"
end

return Terminal