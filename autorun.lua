local Editor = require("editor") --Require the editor
local Terminal = require("terminal")
local RT = require("runtime")

local Active
local EActive = false --Editor Active
local GActive = false --Game Active
local GStarted = false

function _auto_init() --I have to seperate the autorun callbacks from the main ones so games can override the original ones without destroying these.
  Terminal:_init()
  Editor:_init()
  RT:_init()
  
  Active = Terminal
  if Active._redraw then Active:_redraw() end
end

function _auto_exitgame()
  Active = EActive and Editor or Terminal
  if Active._redraw then Active:_redraw() end
  GActive = false
end

function _auto_switchgame()
  GActive, GStarted, Active = true, false, RT
  --RT:startGame()
end

function _auto_update(dt)
  if (not GStarted) and GActive then GStarted = true RT:startGame() end
  if Active._update then Active:_update(dt) end
end

function _auto_mpress(...)
  if Active._mpress then Active:_mpress(...) end
end

function _auto_mmove(...)
  if Active._mmove then Active:_mmove(...) end
end

function _auto_mrelease(...)
  if Active._mrelease then Active:_mrelease(...) end
end

function _auto_tpress(...)
  if Active._tpress then Active:_tpress(...) end
end

function _auto_tmove(...)
  if Active._tmove then Active:_tmove(...) end
end

function _auto_trelease(...)
  if Active._trelease then Active:_trelease(...) end
end

function _auto_kpress(k,sc,ir)
  if k == "escape" then
    if not GActive then EActive = not EActive else GActive = false end
    if EActive then Active = Editor else Active = Terminal end
    if Active._redraw then Active:_redraw() end
  end
  if Active._kpress then Active:_kpress(k,sc,ir) end
end

function _auto_krelease(...)
  if Active._krelease then Active:_krelease(...) end
end

function _auto_tinput(t)
  if Active._tinput then Active:_tinput(t) end
end