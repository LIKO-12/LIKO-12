local perpath = select(1,...) --The path to the FDD folder

local json = require("Engine.JSON")
local events = require("Engine.events")

return function(config)
  
  local sfxr = love.filesystem.load(perpath.."sfxr.lua")()
  local thread = love.thread.newThread(perpath.."loadthread.lua")
  local chIn, chOut = love.thread.newChannel(), love.thread.newChannel()
  
  thread:start(perpath, chIn, chOut)
  
  events:register("love:reboot", function()
    chIn:push("stop")
  end)
  
  events:register("love:quit", function()
    chIn:supply("stop")
    thread:wait()
  end)
  
  local au, devkit, indirect = {}, {}, {}
  
  function au.newSound()
    
    local s = {} --The sound object.
    local sounddata
    
    local params = {
      repeatspeed = 0,
      waveform = 0, --*
      envelope = {
        attack = 0,
        sustain = 0.3,
        punch = 0,
        decay = 0.4
      },
      frequency = {
        start = 0.3,
        min = 0,
        slide = 0, --
        dslide = 0 --
      },
      vibrato = {
        depth = 0,
        speed = 0
      },
      change = {
        amount = 0, --
        speed = 0
      },
      duty = {
        ratio = 0,
        sweep = 0 --
      },
      phaser = {
        offset = 0, --
        sweep = 0
      },
      lowpass = {
        cutoff = 1,
        sweep = 0, --
        resonance = 0
      },
      highpass = {
        cutoff = 0,
        sweep = 0 --
      }
    }
    
    function s:get(field)
      if type(field) ~= "string" then return error("Field should be a string, provided: "..type(field)) end
      
      local i, sub = field:match("(.+)%.(.+)")
      if i then
        if type(params[i]) ~= "table" then
          return error("Field doesn't exists.")
        else
          if type(params[i][sub]) ~= "number" then
            return error("Field doesn't exists")
          else
            return params[i][sub]
          end
        end
      else
        if type(params[field]) ~= "number" then
          return error("Field doesn't exists.")
        end
        
        return params[field]
      end
    end
    
    function s:set(field,value)
      if type(field) ~= "string" then return error("Field should be a string, provided: "..type(field)) end
      if type(value) ~= "number" then return error("Value should be a number, provided: "..type(value)) end
      
      local i, sub = field:match("(.+)%.(.+)")
      if i then
        if type(params[i]) ~= "table" then
          return error("Field doesn't exists.")
        else
          if type(params[i][sub]) ~= "number" then
            return error("Field doesn't exists")
          end
          
          if params[i][sub] ~= value then
            sounddata = false
          end
          params[i][sub] = value
        end
      else
        if type(params[field]) ~= "number" then
          return error("Field doesn't exists.")
        end
        
        if params[field] ~= value then
          sounddata = nil
        end
        params[field] = value
      end
    end
    
    function s:generate()
      if sounddata then return end
      
    end
    
    function s:play()
      self:generate()
      
      local source = love.audio.newSource(sounddata)
      source:play()
    end
    
  end
  
  function au.playRandom()
    
    local sound = sfxr.newSound()
    sound:randomize()
    local sounddata = sound:generateSoundData()
    local source = love.audio.newSource(sounddata)
    source:play()
    
    return true
    
  end
  
  return au, devkit, indirect
  
end