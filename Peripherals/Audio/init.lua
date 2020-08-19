local perpath = ... --The path to the Audio folder

local events = require("Engine.events")

return function(config)
  
  local sfxThreads = {}
  local sfxChannels = {}
  
  for i=0,3 do
    sfxThreads[i] = love.thread.newThread(perpath.."sfxthread.lua")
    sfxChannels[i] = love.thread.newChannel()
  end
  
  local ctunethread = love.thread.newThread(perpath.."ctunethread.lua")
  local chctune = love.thread.newChannel()
  
  for i=0,3 do
    sfxThreads[i]:start(sfxChannels[i])
  end
  ctunethread:start(chctune)
  
  events.register("love:reboot", function()
    for i=0,3 do
      sfxChannels[i]:clear()
      sfxChannels[i]:push("stop")
    end
    chctune:clear()
    chctune:push("stop")
  end)
  
  events.register("love:quit", function()
    for i=0,3 do
      sfxChannels[i]:clear()
      sfxChannels[i]:push("stop")
    end
    chctune:clear()
    chctune:push("stop")
    for i=0,3 do
      sfxThreads[i]:wait()
    end
    ctunethread:wait()
  end)
  
  local AU, yAU, devkit = {}, {}, {}
  
  function AU.generate(wave,freq,amp)
    
    if not wave then
      chctune:clear()
      chctune:push({})
      return
    end
    
    if type(wave) ~= "number" then return error("Waveform id should be a number, provided: "..type(wave)) end
    if type(freq) ~= "number" then return error("Frequency should be a number, provided: "..type(freq)) end
    if type(amp) ~= "number" then return error("Amplitude should be a number, provided: "..type(amp)) end
    
    wave = math.floor(wave)
    if wave < 0 or wave > 5 then return error("Waveform id is out of range ("..wave.."), should be in [0,5]") end
    
    freq = math.abs(freq)
    amp = math.abs(amp)
    
    chctune:clear()
    chctune:push({wave,freq,amp})
    
  end
  
  function AU.stop()
    chctune:clear()
    chctune:push({})
    for i=0,3 do
      sfxChannels[i]:clear()
      sfxChannels[i]:push({})
    end
  end
  
  function AU.play(sfx,chn)
    
    if type(sfx) ~= "table" then return error("SFX data should be a table, provided: "..type(sfx)) end
    if #sfx % 4 > 0 then return error("The SFX data is missing some values.") end
    for k,v in ipairs(sfx) do
      if type(k) ~= "number" then
        return error("SFX Data shouldn't contain any non-number indexes ["..tostring(k).."]")
      end
      
      if type(v) ~= "number" then
        return error("SFX Data [#"..k.."] should be a number, provided: "..type(v))
      end
    end
    
    local sendSFX = {}
    for k,v in ipairs(sfx) do
      --Squares amplitude. This produces exponential volume instead of linear.
      if k % 4 == 0 then
       v = v*v
      end
      
      sendSFX[k] = v
    end
    
    chn = chn or 0
    
    if type(chn) ~= "number" then return error("Channel should be a number or a nil, provided: "..type(chn)) end
    
    chn = math.floor(chn)
    
    if chn < 0 or chn > 3 then return error("Channel is out of range ("..chn.."), should be in [0,3]") end
    
    sfxChannels[chn]:clear()
    sfxChannels[chn]:push(sendSFX)
    
  end
  
  events.register("love:update", function(dt)
    
    for i=0,3 do
      local terr = sfxThreads[i]:getError()
      if terr then
        error("SFXThread #"..i..": "..terr)
      end
    end
    
    local terr = ctunethread:getError()
    if terr then
      error("GenThread: "..terr)
    end
    
  end)
  
  return AU, yAU, devkit
  
end