local Editor = {}

Editor.Current = {}
Editor.curid = 3
Editor.editors = {"console","code","sprite","sprite","sprite","sprite"}

local ModeGrid = {192-8*#Editor.editors,1,8*#Editor.editors,8,#Editor.editors,1}

function Editor:_init()
  self:switchEditor(self.curid)
  for _,e in pairs(Editor.editors) do
    local m = require("editor."..e)
    if m._init then m:_init() end
  end
end

function Editor:_redraw()
  self:redrawUI()
  if self.Current._redraw then self.Current:_redraw() end
end

function Editor:redrawUI()
  api.clear(6)
  api.rect(1,1,192,8,9)
  api.rect(1,128-7,192,8,9)
  api.SpriteGroup(24-#Editor.editors+1,192-8*#Editor.editors,1,#Editor.editors,1,1,1,EditorSheet)
  EditorSheet:draw((48-#Editor.editors)+self.curid,(192-8*#Editor.editors)+self.curid*8-8,1)
  api.SpriteGroup(63,1,1,4,1,1,1,EditorSheet)
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
  local cx = api.whereInGrid(x,y,ModeGrid)
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