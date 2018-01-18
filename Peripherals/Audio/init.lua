local perpath = select(1,...) --The path to the Audio folder

local json = require("Engine.JSON")
local coreg = require("Engine.coreg")
local events = require("Engine.events")

return function(config)
  
  local sfxr = love.filesystem.load(perpath.."sfxr.lua")()
  local thread = love.thread.newThread(perpath.."sfxrthread.lua")
  local chIn = love.thread.newChannel()
  
  thread:start(chIn)
  
  events:register("love:reboot", function()
    chIn:push("stop")
  end)
  
  events:register("love:quit", function()
    chIn:supply("stop")
    thread:wait()
  end)
  
  local AU, yAU, devkit = {}, {}, {}
  
  function AU.play(chn,p)
    
    if type(p) ~= "table" then return error("Parameters should be a table, provided: "..type(p)) end
    
    local params = {repeatspeed=0,waveform=0,envelope={attack=0,sustain=0.3,punch=0,decay=0.4},frequency={start=0.3,min=0,slide=0,dslide=0},vibrato={depth=0,speed=0},change={amount=0,speed=0},duty={ratio=0,sweep=0},phaser={offset=0,sweep=0},lowpass={cutoff=1,sweep=0,resonance=0},highpass={cutoff=0,sweep=0}}
    
    for k1,v1 in pairs(p) do
      if type(v1) == "table" and type(params[k1]) == "table" then
        for k2,v2 in pairs(v1) do
          if type(v2) == "number" and type(params[k1][k2]) == "number" then
            params[k1][k2] = v2
          end
        end
      elseif type(v1) == "number" then
        if type(params[k1]) == "number" then
          params[k1] = v1
        end
      end
    end
    
    local job = json:encode(params)
    
    chIn:push({channel=chn or 1,params=job})
    
  end
  
  events:register("love:update", function(dt)
    
    local terr = thread:getError()
    if terr then
      error("Thread: "..terr)
    end
    
  end)
  
  return AU, yAU, devkit
  
end