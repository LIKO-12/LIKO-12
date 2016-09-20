local cedit = {}

local colorize = require("libraries.colorize_lua")

cedit.colors = {
text = _GetColor(8),
keyword = _GetColor(11),--15),
number = _GetColor(13),--13),
comment = _GetColor(14),
str = _GetColor(13),
}

function cedit:resetBuffer()
  self.buffer = TextBuffer(1,2,45,14,0,0,0)
  function self.buffer:_redraw() --To add syntax highlighting
    api.rect(1,9,192,128-16,6) api.color(7)
    local dbuff, gx,gy, sr = self:getLinesBuffer()
    local cbuff = colorize(dbuff,cedit.colors)
    api.color(8)
    for line, text in ipairs(cbuff) do
      api.print(text, (gx*8-6)-sr*4,(gy+line-1)*8-6)
    end
    api.rect(1,128-7,192,8,10)
    api.color(5)
    api.print("LINE "..self.cursorY.."/"..#self.buffer,2,128-5)
  end
end

function cedit:export()
  if not self.buffer then self:resetBuffer() end
  local code, buff = "", self.buffer:getBuffer()
  for line,text in ipairs(buff) do
    code = code..text.."\n"
  end
  return code
end

local function magiclines(s)
  if s:sub(-1)~="\n" then s=s.."\n" end
  return s:gmatch("(.-)\n")
end

function cedit:load(code)
  --self.codebuffer, self.topLine, self.cursorX, self.cursorY = {}, 0, 1, 1
  self:resetBuffer()
  self.buffer.buffer = {}
  if not code then return self end
  local code = code
  for line in magiclines(code) do
    table.insert(self.buffer.buffer,line)
  end
  return self
end

function cedit:_switch()
  
end

function cedit:_redraw()
  self.buffer:_redraw()
  --api.rect(1,9,192,128-16,6) api.color(7)
  --[[local tocolor = {}
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
  api.print("LINE "..self.topLine+self.cursorY.."/"..#self.codebuffer,2,128-5)]]
  
  --[[for i=self.topLine+1,self.topLine+self.lineLimit do
    if self.codebuffer[i] then api.print_grid(self.codebuffer[i],1,(i-self.topLine)+1) end
  end]]
end

function cedit:_update(dt)
  self.buffer:_update(dt)
end

function cedit:_mmove(x,y,dx,dy,it,iw)
  if math.abs(y) > 5 then return end --Dead mouse wheel strike
  if math.abs(x) > 5 then return end --Dead mouse wheel strike
  if y > 0 then
    self.buffer:_kpress("up",0,false)
  elseif y < 0 then
    self.buffer:_kpress("down",0,false)
  end
  
  if x > 0 then
    self.buffer:_kpress("right",0,false) --Maybe ? or inverted..
  elseif x < 0 then
    self.buffer:_kpress("left",0,false)
  end
end

function cedit:_kpress(k,sc,ir)
  self.buffer:_kpress(k,sc,ir)
end

function cedit:_tinput(t)
  self.buffer:_tinput(t)
end

function cedit:_tpress()
  --This means the user is using a touch device
  --self.lineLimit = 7
  api.showkeyboard(true)
end

cedit:resetBuffer()

return cedit
