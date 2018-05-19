--Complete the standard Lua functions.

local Globals = (...) or {}
local co = select(2,...) or {}

local function callevfunc(evf, a,b,c,d,e,f)
  if evf and type(evf) == "function" then
    local ok, err = pcall(evf, a,b,c,d,e,f)
    if not ok then
      local err = tostring(err)
      if err:sub(1,12) == '[string ""]:' then err = err:sub(13,-1) end
      coroutine.yield("RUN:exit", "ERR :"..err)
      return false
    end
  end
  
  return true
end

local function evloop()
  
  if not callevfunc(Globals["_init"]) then return end
  
  if not ((Globals["_update"] and type(Globals["_update"]) == "function") or (Globals["_draw"] and type(Globals["_draw"]) == "function") or Globals["_eventLoop"]) then
    return
  end
  
  local time30, time60 = 1/30, 1/60
  local timer30, timer60 = 0, 0
  
  while true do
    local event, a,b,c,d,e,f = pullEvent()
    
    if not callevfunc(Globals["_"..event], a,b,c,d,e,f) then return end
    
    if event == "update" then
      if not callevfunc(Globals["_draw"], a,b,c,d,e,f) then return end
    end
    
    if event == "update" and (Globals["_update60"] or Globals["_draw60"]) then
      timer60 = timer60 + a
      
      if timer60 >= time60 then
        timer60 = timer60 % time60
        
        if not callevfunc(Globals["_update60"]) then return end
        if not callevfunc(Globals["_draw60"]) then return end
      end
    end
    
    if event == "update" and (Globals["_update30"] or Globals["_draw30"]) then
      timer30 = timer30 + a
      
      if timer30 >= time30 then
        timer30 = timer30 % time30
        
        if not callevfunc(Globals["_update30"]) then return end
        if not callevfunc(Globals["_draw30"]) then return end
      end
    end
    
    if event == "keypressed" then
      Globals.__BTNKeypressed(a,c)
    elseif event == "update" then
      Globals.__BTNUpdate(a)
    elseif event == "touchcontrol" then
      Globals.__BTNTouchControl(a,b)
    elseif event == "gamepad" then
      Globals.__BTNGamepad(a,b,c)
    end
  end
end

local evco = coroutine.create(evloop)
Globals.__evco = evco --So the the runtime recieves the event loop coroutine.

--Lua functions--

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
  if co and (curco == co or evco == co) then return end
  return curco
end

Globals.dofile = function(path,...)
  local chunk, err = fs.load(path)
  if not chunk then return error(err) end
  setfenv(chunk,Globals)
  local ok, err = pcall(chunk,...)
  if not ok then return error(err) end
end

return Globals