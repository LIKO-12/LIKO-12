local perpath = select(1,...) --The path to the Audio folder

local events = require("Engine.events")

return function(config)
  
  local sfxThreads = {}
  local sfxChannels = {}
  local ctuneThreads = {}
  local ctuneChannels = {}
  
  for i=0,3 do
    sfxThreads[i] = love.thread.newThread(perpath.."sfxthread.lua")
    sfxChannels[i] = love.thread.newChannel()
	ctuneThreads[i] = love.thread.newThread(perpath.."ctunethread.lua")
	ctuneChannels[i] = love.thread.newChannel()
  end
  
  --local ctunethread = love.thread.newThread(perpath.."ctunethread.lua")
  --local chctune = love.thread.newChannel()
  
  for i=0,3 do
    sfxThreads[i]:start(sfxChannels[i])
	ctuneThreads[i]:start(ctuneChannels[i])
  end
  
  
  events.register("love:reboot", function()
    for i=0,3 do
      sfxChannels[i]:clear()
      sfxChannels[i]:push("stop")
	  ctuneChannels[i]:clear()
	  ctuneChannels[i]:push("stop")
    end
  end)
  
  events.register("love:quit", function()
    for i=0,3 do
      sfxChannels[i]:clear()
      sfxChannels[i]:push("stop")
	  ctuneChannels[i]:clear()
	  ctuneChannels[i]:push("stop")
    end
    
    for i=0,3 do
      sfxThreads[i]:wait()
	  ctuneThreads[i]:wait()
    end
  end)
  
  local AU, yAU, devkit = {}, {}, {}
  
  function AU.generate(wave,freq,amp,channel)
    -- Clear the channel of audio
    if not wave then
	  if channel == nil then
		for i=0,3 do
			ctuneChannels[i]:clear()
			ctuneChannels[i]:push({})
		end
	  else
	    ctuneChannels[channel]:clear()
		ctuneChannels[channel]:push({})
	  end
      return
    end
    
    if type(wave) ~= "number" then return error("Waveform id should be a number, provided: "..type(wave)) end
    if type(freq) ~= "number" then return error("Frequency should be a number, provided: "..type(freq)) end
    if type(amp) ~= "number" then return error("Amplitude should be a number, provided: "..type(amp)) end
    
    wave = math.floor(wave)
    if wave < 0 or wave > 5 then return error("Waveform id is out of range ("..wave.."), should be in [0,5]") end
    
    freq = math.abs(freq)
    amp = math.abs(amp)
    -- Default channel is 0 when not provided
	channel = channel or 0
	
    ctuneChannels[channel]:clear()
    ctuneChannels[channel]:push({wave,freq,amp})
    
  end
  
  function AU.stop()
    for i=0,3 do
      sfxChannels[i]:clear()
      sfxChannels[i]:push({})
	  ctuneChannels[i]:clear()
	  ctuneChannels[i]:push({})
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
    for i=0,3 do
      local terr = ctuneThreads[i]:getError()
      if terr then
        error("CTuneThread #"..i..": "..terr)
      end
	end
    
  end)
  
  return AU, yAU, devkit
  
end