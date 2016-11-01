local cedit = {}

local colorize = require("libraries.colorize_lua")

cedit.colors = {
text = _GetColor(8),
keyword = _GetColor(11),--15),
number = _GetColor(13),--13),
comment = _GetColor(14),
str = _GetColor(13),
}

function cedit:_init()
  self:resetBuffer()
  self.keymap = self.keymap or {}
end

function cedit:resetBuffer()
  self.buffer = api.TextBuffer(1,2,47,14,0,0,0)
  self.parent = self.buffer
  self.buffer.parent = require("editor")
  function self.buffer:_redraw() --To add syntax highlighting
    api.rect(1,9,192,128-16,6)
    local dbuff, gx,gy, sr = self:getLinesBuffer()
    local cbuff = colorize(dbuff,cedit.colors)
    api.pushColor()
    love.graphics.setColor(255,255,255,255)
    for line, text in ipairs(cbuff) do
      api.print(text, (gx*8-6)-sr*4,(gy+line-1)*8-6)
    end
    api.rect(1,128-7,192,8,10)
    api.color(5)
    api.print("LINE "..self.cursorY.."/"..#self.buffer.."  CHAR "..(self.cursorX-1).."/"..self.buffer[self.cursorY]:len(),2,128-5)
    api.popColor()
  end
end

function cedit:export()
  if not self.buffer then self:resetBuffer() end
  return table.concat(self.buffer:getBuffer(), "\n")
end

local function magiclines(s)
  if s:sub(-1)~="\n" then s=s.."\n" end
  return s:gmatch("(.-)\n")
end

function cedit:load(code)
  self:resetBuffer()
  self.buffer.buffer = {}
  for line in magiclines(code or "") do
    table.insert(self.buffer.buffer,line)
  end
  return self
end

function cedit:_switch()
  
end

function cedit:_redraw()
  self.buffer:_redraw()
end

function cedit:_update(dt)
  self.buffer:_update(dt)
end

function cedit:_mmove(x,y,dx,dy,it,iw)
  if math.abs(y) > 5 then return end --Dead mouse wheel strike
  if math.abs(x) > 5 then return end --Dead mouse wheel strike
  if y > 0 then
    self.buffer.keymap["up"](self.buffer,false) self:_redraw()
  elseif y < 0 then
    self.buffer.keymap["down"](self.buffer,false) self:_redraw()
  end
  
  if x > 0 then
    self.buffer.keymap["right"](self.buffer,false) self:_redraw() --Maybe ? or inverted..
  elseif x < 0 then
    self.buffer.keymap["left"](self.buffer,false) self:_redraw()
  end
end

function cedit:_tinput(t)
  self.buffer:_tinput(t)
end

function cedit:_tpress()
  --This means the user is using a touch device
  --self.lineLimit = 7
  api.showkeyboard(true)
end

return cedit
