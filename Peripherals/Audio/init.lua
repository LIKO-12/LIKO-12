local perpath = select(1,...) --The path to the Audio folder

local json = require("Engine.JSON")
local coreg = require("Engine.coreg")
local events = require("Engine.events")

return function(config)
  
  local sfxthread = love.thread.newThread(perpath.."sfxthread.lua")
  local chsfx = love.thread.newChannel()
  
  local ctunethread = love.thread.newThread(perpath.."ctunethread.lua")
  local chctune = love.thread.newChannel()
  
  sfxthread:start(chsfx)
  ctunethread:start(chctune)
  
  events:register("love:reboot", function()
    chsfx:clear()
    chsfx:push("stop")
    chctune:clear()
    chctune:push("stop")
  end)
  
  events:register("love:quit", function()
    chsfx:clear()
    chsfx:push("stop")
    chctune:clear()
    chctune:push("stop")
    sfxthread:wait()
    ctunethread:wait()
  end)
  
  local AU, yAU, devkit = {}, {}, {}
  
  function AU.generate(wave,freq,amp)
    chctune:clear()
    chctune:push({wave,freq,amp})
  end
  
  function AU.stop()
    chctune:clear()
    chctune:push({})
    chsfx:clear()
    chsfx:push({})
  end
  
  function AU.play(sfx)
    
    chsfx:clear()
    chsfx:push(sfx)
    
  end
  
  events:register("love:update", function(dt)
    
    local terr = sfxthread:getError()
    if terr then
      error("Thread: "..terr)
    end
    
    local terr = ctunethread:getError()
    if terr then
      error("Thread: "..terr)
    end
    
  end)
  
  return AU, yAU, devkit
  
end