--Complete the standard Lua functions.

local Globals = (...) or {}
local co = select(2,...) or {}

Globals.getfenv = function(f)
  if type(f) ~= "function" then return error("bad argument #1 to 'getfenv' (function expected, got "..type(f)) end
  local ok, env = pcall(getfenv,f)
  if not ok then return error(env) end
  if env == _G then env = {} end --Protection
  return env
end

Globals.setfenv = function(f,env)
  if type(f) ~= "function" then return error("bad argument #1 to 'setfenv' (function expected, got "..type(f)) end
  if type(env) ~= "table" then return error("bad argument #2 to 'setfenv' (table expected, got "..type(env)) end
  local oldenv = getfenv(f)
  if oldenv == _G then return end --Trying to make a crash ! evil.
  local ok, err = pcall(setfenv,f,env)
  if not ok then return error(err) end
end

Globals.loadstring = function(data)
  local chunk, err = loadstring(data)
  if not chunk then return nil, err end
  setfenv(chunk,glob)
  return chunk
end

Globals.coroutine.running = function()
  local curco = coroutine.running()
  if co and curco == co then return end
  return curco
end

Globals.dofile = function(path)
  local chunk, err = fs.load(path)
  if not chunk then return error(err) end
  setfenv(chunk,Globals)
  local ok, err = pcall(chunk)
  if not ok then return error(err) end
end

return Globals