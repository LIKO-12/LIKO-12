--Corouting Registry: this file is responsible for providing LIKO12 it's api--
local coreg = {reg={}}

--Returns the current active coroutine if exists
function coreg:getCoroutine()
  return self.co
end

--Sets the current active coroutine
function coreg:setCoroutine(co)
  self.co  = co
  return self
end

local function extractArgs(args,factor)
  local nargs = {}
  for k,v in ipairs(args) do
    if k > factor then table.insert(nargs,v) end
  end
  return nargs
end

--Resumes the current active coroutine if exists.
function coreg:resumeCoroutine(...)
  if not self.co or coroutine.status(self.co) == "dead" then return end
  local args = {coroutine.resume(self.co,...)}
  if not args[1] then error(args[2]) end --Should have a better error handelling
  if not args[2] then
    --if self.co:status() == "dead" then error("done") return end --OS finished ??
    --self:resumeCoroutine()
    self.co = nil return
  end
  args = {self:trigger(args[2],unpack(extractArgs(args,2)))}
  if not args[1] then self:resumeCoroutine(args[1],unpack(extractArgs(args,1))) end
  if not(type(args[1]) == "number" and args[1] == 2) then
    self:resumeCoroutine(true,unpack(extractArgs(args,1)))
  end
end

function coreg:sandboxCoroutine(f)
  local GLOB = {
    assert=assert,
    error=error,
    ipairs=ipairs,
    pairs=pairs,
    next=next,
    pcall=pcall,
    select=select,
    tonumber=tonumber,
    tostring=tostring,
    type=type,
    unpack=unpack,
    _VERSION=_VERSION,
    xpcall=xpcall,
    getfenv=getfenv,
    setfenv=setfenv,
    string={
      byte=string.byte,
      char=string.char,
      find=string.find,
      format=string.format,
      gmatch=string.gmatch,
      gsub=string.gsub,
      len=string.len,
      lower=string.lower,
      match=string.match,
      rep=string.rep,
      reverse=string.reverse,
      sub=string.sub,
      upper=string.upper
    },
    table={
      insert=table.insert,
      maxn=table.maxn,
      remove=table.remove,
      sort=table.sort
    },
    math={
      abs=math.abs,
      acos=math.acos,
      asin=math.asin,
      atan=math.atan,
      atan2=math.atan2,
      ceil=math.ceil,
      cos=math.cos,
      cosh=math.cosh,
      deg=math.deg,
      exp=math.exp,
      floor=math.floor,
      fmod=math.fmod,
      frexp=math.frexp,
      huge=math.huge,
      ldexp=math.ldexp,
      log=math.log,
      log10=math.log10,
      max=math.max,
      min=math.min,
      modf=math.modf,
      pi=math.pi,
      pow=math.pow,
      rad=math.rad,
      random=love.math.random, --Replaced with love.math versions
      randomseed=love.math.setRandomSeed,
      sin=math.sin,
      sinh=math.sinh,
      sqrt=math.sqrt,
      tan=math.tan,
      tanh=math.tanh,
      noise = love.math.noise --LOVE releated apis
    },
    coroutine={
      resume = coroutine.resume,
      yield = coroutine.yield,
      status = coroutine.status
    },
    os={
      time=os.time,
      clock=os.clock
    }
  }
  GLOB.loadstring = function(...)
    local chunk, err = loadstring(...)
    if not chunk then return nil, err end
    setfenv(chunk,GLOB)
    return chunk
  end
  GLOB.coroutine.create = function(...)
    local co,err = pcall(coroutine.create,...)
    if not co then return error(err) end
    setfenv(co,GLOB)
    return co 
  end
  GLOB._G=GLOB --Mirror Mirror
  setfenv(f,GLOB)
end

--Register a value to a specific key.
--If the value is a table, then the values in the table will be registered at key:tableValueKey
--If the value is a function, then it will be called instantly, and it must return true as the first argument to tell that it ran successfully.
--Else, the value will be returned to the liko12 code.
function coreg:register(value,key)
  local key = key or "none"
  if type(value) == "table" then
    for k,v in pairs(value) do
      self.reg[key..":"..k] = v
    end
  end
  self.reg[key] = value
end

--Trigger a value in a key.
--If the value is a function, then it will call it instant.
--Else, it will return the value.
--Notice that the first return value is a number of "did it ran successfully", if false, the second return value is the error message.
--Also the first return value could be also a number that specifies how should the coroutine resume (true boolean defaults to 1)
--Corouting resumming codes: 1: resume instantly, 2: stop resuming (Will be yeild later, like when love.update is called).
function coreg:trigger(key,...)
  local key = key or "none"
  if type(self.reg[key]) == "nil" then return false, "error, key not found !" end
  if type(self.reg[key]) == "function" then
    return self.reg[key](...)
  else
    return true, self.reg[key]
  end
end

--Returns the value registered in a specific key.
--Returns: value then the given key.
function coreg:get(key)
  local key = key or "none"
  return self.reg[key], key
end

--Returns a table containing the list of the registered keys.
--list[key] = type
function coreg:index()
  local list = {}
  for k,v in pairs(self.reg) do
    list[k] = type(v)
  end
  return list
end

--Returns a clone of the registry table.
function coreg:registry()
  local reg = {}
  for k,v in pairs(self.reg) do
    reg[k] = v
  end
  return reg
end

return coreg