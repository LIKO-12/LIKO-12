local Editor = {}
Editor.Current = {}

Editor.Sheet = SpriteSheet(Image("/editorsheet.png"),24,12)
--SpriteMap = Editor.Sheet

function Editor:_startup()
  self:switchEditor("sprite")
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
  SpriteGroup(63,1,1,4,1,self.Sheet)
end

function Editor:switchEditor(new)
  self.Current = require("editor."..new)
  if self.Current._switch then self.Current:_switch() end
  self:_redraw()
end

function Editor:_update(dt)
  if self.Current._update then self.Current:_update(dt) end
end

function Editor:_mpress(x,y,b,it)
  if self.Current._mpress then self.Current:_mpress(x,y,b,it) end
end

function Editor:_mmove(x,y,dx,dy,it)
  if self.Current._mmove then self.Current:_mmove(x,y,dx,dy,it) end
end

function Editor:_mrelease(x,y,b,it)
  if self.Current._mrelease then self.Current:_mrelease(x,y,b,it) end
end

return Editor