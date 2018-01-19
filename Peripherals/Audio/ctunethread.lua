--Chiptune Thread

local chIn = ...

require("love.audio")
require("love.sound")
require("love.timer")

local QSource = require("Peripherals.Audio.QueueableSource")

local qs = QSource:new()

local rate = 44100
local buffer_size = rate/4
local sleeptime = 0.9/(rate/buffer_size)

local wave, freq, amp

local waves = {}

--Sin
waves[0] = function(samples)
  local r = 0
  
  return function()
    r = r + math.pi/(samples/2)
    
    return math.sin(r)*amp
  end
end

--Square
waves[1] = function(samples)
  local c = 0
  local flag = false
  
  return function()
    c = (c+1)%(samples/2)
    if c == 0 then flag = not flag end
    
    return (flag and amp or -amp)
  end
end

--Sawtooth
waves[2] = function(samples)
  local c = 0
  local inc = 2/samples
  
  return function()
    c = (c+inc)%2 -1
    return c
  end
end

waves[3] = function(samples)
  local c = samples/2
  local v = math.random()
  local flag = flag
  
  return function()
    --[[c = c -1
    if c == 0 then
      c = samples/2
      flag = not flag
      v = math.random()*2
      if flag then v = -v end
    end
    
    return v*amp
    ]]
  
    return math.random()*2-1
  end
end


local function pullParams()
  if wave then
    return chIn:pop()
  else
    return chIn:demand()
  end
end

while true do
  for params in pullParams do
    if type(params) == "string" and params == "stop" then
      return
    else
      local ofreq = freq
      wave, freq, amp = unpack(params)
      
      if ofreq then
        --error(ofreq.." -> "..freq)
      end
      --error(tostring(wave).."_"..tostring(freq).."_"..tostring(amp))
      
      --amp = amp or 1
      
      qs:clear()
      
      qs = QSource:new()
      
      chIn:clear()
    end
  end
  
  --Generate audio.
  if wave then
    qs:step()
    
    if qs:getFreeBufferCount() > 0 then
      local sd = love.sound.newSoundData(buffer_size, rate, 16, 1)
      local gen = waves[wave](rate/freq)
      for i=0,buffer_size-1 do
        sd:setSample(i,gen())
      end
      
      qs:queue(sd)
      qs:play()
    end
  end
  
  love.timer.sleep(sleeptime)
end