--A function that creates new sandboxed global environment.

local basexx = require("Engine.basexx")
local bit = require("bit")

return function()
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
    setmetatable=setmetatable,
    getmetatable=getmetatable,
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
      sort=table.sort,
      concat=table.concat
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
      noise = love.math.noise, --LOVE releated apis
      b64enc = basexx.to_base64, --Will be replaced by love.math ones in love 0.11
      b64dec = basexx.from_base64,
      hexenc = basexx.to_hex,
      hexdec = basexx.from_hex,
      compress = function(...) return love.math.compress(...):getString() end,
      decompress = love.math.decompress
    },
    coroutine={
      resume = coroutine.resume,
      yield = coroutine.yield,
      status = coroutine.status
    },
    os={
      time=os.time,
      clock=os.clock
    },
    bit={
      cast=bit.cast,
      bnot=bit.bnot,
      band=bit.band,
      bor=bit.bor,
      bxor=bit.bxor,
      lshift=bit.lshift,
      rshift=bit.rshift,
      arshift=bit.arshift,
      tobit=bit.tobit,
      tohex=bit.tohex,
      rol=bit.rol,
      ror=bit.ror,
      bswap=bit.swap
    }
  }
  GLOB.loadstring = function(...)
    local chunk, err = loadstring(...)
    if not chunk then return nil, err end
    setfenv(chunk,GLOB)
    return chunk
  end
  GLOB.coroutine.create = function(chunk)
    --if type(chunk) == "function" then setfenv(chunk,GLOB) end
    local ok,co = pcall(coroutine.create,chunk)
    if not ok then return error(co) end
    return co 
  end
  GLOB.coroutine.sethook = function(co,...)
    if type(co) ~= "thread" then return error("wrong argument #1 (thread expected, got "..type(co)..")") end
    local ok, err = pcall(debug.sethook,co,...)
    if not ok then return error(err) end
    return err
  end
  GLOB._G=GLOB --Mirror Mirror
  return GLOB
end