local Editor = {}

Editor.Current = {}
Editor.curid = 3
Editor.editors = {"console","code","sprite","tile","sprite","sprite"}

local ModeGrid = {192-8*#Editor.editors,1,8*#Editor.editors,8,#Editor.editors,1}
local ModeMFlag = false

function Editor:_init()
  self:switchEditor(self.curid)
  for _,e in pairs(Editor.editors) do
    local m = require("editor."..e)
    if m._init then m:_init(Editor) end
    if not m.keymap then m.keymap = {} end
    if not m.parent then m.parent = Editor end
  end

  local init_path = (os.getenv("HOME") or "") .. "/.liko12/init.lua"
  local init_file = io.open(init_path)
  if(init_file) then
    init_file:close()
    local ok, err = pcall(dofile, init_path)
    if(not ok) then print(err) end
  end
end

function Editor:_redraw()
  self:redrawUI()
  if self.Current._redraw then self.Current:_redraw() end
end

function Editor:redrawUI()
  api.clear(6)
  api.rect(1,1,192,8,10)
  api.rect(1,128-7,192,8,10)
  api.SpriteGroup(24-#Editor.editors+1,192-8*#Editor.editors,1,#Editor.editors,1,1,1,api.EditorSheet)
  api.EditorSheet:draw((48-#Editor.editors)+self.curid,(192-8*#Editor.editors)+self.curid*8-8,1)
  api.SpriteGroup(55,1,1,4,1,1,1,api.EditorSheet)
end

function Editor:switchEditor(id)
  self.Current, self.curid = require("editor."..self.editors[id]), id
  if self.Current._switch then self.Current:_switch() end
  self:_redraw()
end

function Editor:_update(dt)
  local mx, my = api.getMPos()
  if api.isInRect(mx,my,ModeGrid) then
    if api.isMDown(1) then
      api.setCursor("handpress")
    else
      api.setCursor("handrelease")
    end
  else
    api.setCursor("normal")
  end
  if self.Current._update then self.Current:_update(dt) end
end

function Editor:_mpress(x,y,b,it)
  if self.Current._mpress then self.Current:_mpress(x,y,b,it) end
  local cx = api.whereInGrid(x,y,ModeGrid)
  if cx then
    self:switchEditor(cx)
    self:_redraw()
    ModeMFlag = true
  end
end

function Editor:_mmove(x,y,dx,dy,it)
  if self.Current._mmove then self.Current:_mmove(x,y,dx,dy,it) end
  local cx = api.whereInGrid(x,y,ModeGrid)
  if cx and ModeMFlag then
    self:switchEditor(cx)
    self:_redraw()
  end
end

function Editor:_mrelease(x,y,b,it)
  if self.Current._mrelease then self.Current:_mrelease(x,y,b,it) end
  local cx = api.whereInGrid(x,y,ModeGrid)
  if cx and ModeMFlag then
    self:switchEditor(cx)
    self:_redraw()
  end
  ModeMFlag = false
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

local key_for = function(k)
  if(love.keyboard.isDown("lalt", "ralt")) then
    k = "alt-" .. k
  end
  if(love.keyboard.isDown("lctrl", "rctrl", "capslock")) then
    k = "ctrl-" .. k
  end
  if(love.keyboard.isDown("lshift", "rshift")) then
    k = "shift-" .. k
  end
  return k
end

function Editor.find_binding(key, mode)
  if mode.keymap[key] then return mode.keymap[key], mode end
  if mode.parent then return Editor.find_binding(key, mode.parent) end
end

function Editor:_kpress(k,sc,ir)
  local command, mode = Editor.find_binding(key_for(k), self.Current)
  if command then
    command(mode)
    mode:_redraw()
  elseif self.Current._kpress then
    self.Current:_kpress(k,sc,ir)
  end
end

Editor.keymap = {
  ["ctrl-pageup"] = function(self)
    Editor:switchEditor(1 + ((Editor.curid - 2) % #Editor.editors))
  end,
  ["ctrl-pagedown"] = function(self)
    Editor:switchEditor(1 + (Editor.curid % #Editor.editors))
  end,
}

function Editor:_krelease(k,sc)
  if self.Current._krelease then self.Current:_krelease(k,sc) end
end

function Editor:_tinput(t)
  if self.Current._tinput then self.Current:_tinput(t) end
end

return Editor
