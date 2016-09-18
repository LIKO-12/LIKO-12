local Editor = require("editor") --Require the editor
local Terminal = require("terminal")

local Acitve
local EActive = false --Editor Active

function _auto_startup() --I have to seperate the autorun callbacks from the main ones so games can override the original ones without destroying these.
  Terminal:_startup()
  Editor:_startup()
  
  Active = Terminal
  if Active._redraw then Active:_redraw() end
end

function _auto_update(dt)
  if Active._update then Active:_update(dt) end
end

function _auto_mpress(x,y,b,it)
  if Active._mpress then Active:_mpress(x,y,b,it) end
end

function _auto_mmove(x,y,dx,dy,it)
  if Active._mmove then Active:_mmove(x,y,dx,dy,it) end
end

function _auto_mrelease(x,y,b,it)
  if Active._mrelease then Active:_mrelease(x,y,b,it) end
end

function _auto_tpress(id,x,y,p)
  if Active._tpress then Active:_tpress(id,x,y,p) end
end

function _auto_tmove(id,x,y,p)
  if Active._tmove then Active:_tmove(id,x,y,p) end
end

function _auto_trelease(id,x,y,p)
  if Active._trelease then Active:_trelease(id,x,y,p) end
end

function _auto_kpress(k,sc,ir)
  if k == "escape" then
    if EActive then Active = Terminal else Active = Editor end  EActive = not EActive
    if Active._redraw then Active:_redraw() end
  end
  if Active._kpress then Active:_kpress(k,sc,ir) end
end

function _auto_krelease(k,sc)
  if Active._krelease then Active:_krelease(k,sc) end
end

function _auto_tinput(t)
  if Active._tinput then Active:_tinput(t) end
end