local Editor = {}

local ModeGrid = {192-8*5,1,8*5,8,5,1}

Editor.Current = {}
Editor.curid = 2
Editor.editors = {"code","sprite","sprite","sprite","sprite"}

Editor.Sheet = SpriteSheet(Image("/editorsheet.png"),24,12)
--SpriteMap = Editor.Sheet

function Editor:_startup()
  self:switchEditor(self.curid)
end

function Editor:_redraw()
  self:redrawUI()
  if self.Current._redraw then self.Current:_redraw() end
end

function Editor:redrawUI()
  clear(6)
  rect(1,1,192,8,9)
  rect(1,128-7,192,8,9)
  SpriteGroup(20,192-8*5,1,5,1,self.Sheet)
  self.Sheet:draw(43+self.curid,(192-8*5)+self.curid*8-8,1)
  SpriteGroup(63,1,1,4,1,self.Sheet)
end

function Editor:switchEditor(id)
  self.Current, self.curid = require("editor."..self.editors[id]), id
  if self.Current._switch then self.Current:_switch() end
  self:_redraw()
end

function Editor:_update(dt)
  if self.Current._update then self.Current:_update(dt) end
end

function Editor:_mpress(x,y,b,it)
  if self.Current._mpress then self.Current:_mpress(x,y,b,it) end
  local cx = whereInGrid(x,y,ModeGrid)
  if cx then
    self:switchEditor(cx)
    self:_redraw()
  end
end

function Editor:_mmove(x,y,dx,dy,it)
  if self.Current._mmove then self.Current:_mmove(x,y,dx,dy,it) end
end

function Editor:_mrelease(x,y,b,it)
  if self.Current._mrelease then self.Current:_mrelease(x,y,b,it) end
end

function Editor:_tpress(id,x,y,p)
  if self.Current._tpress then self.Current:_tpress(id,x,y,p) end
end

function Editor:_tmove(id,x,y,p)
  if self.Current._tmove then self.Current:_tmove(id,x,y,p) end
end

function Editor:_trelease(id,x,y,p)
  if self.Current._trelease then self.Current:_trelease(id,x,y,p) end
end

function Editor:_kpress(k,sc,ir)
  if self.Current._kpress then self.Current:_kpress(k,sc,ir) end
end

function Editor:_krelease(k,sc)
  if self.Current._krelease then self.Current:_krelease(k,sc) end
end

function Editor:_tinput(t)
  if self.Current._tinput then self.Current:_tinput(t) end
end

return Editor