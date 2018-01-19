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

local wave, freq, amp, gen

local waves = {}

--Sin
waves[0] = function(samples)
  local r = 0
  
  local hs = samples/2
  local pi = math.pi
  local dpi = pi*1
  
  return function()
    r = (r + pi/hs)%dpi
    
    return math.sin(r)*amp
  end
end

--Square
waves[1] = function(samples)
  local c = 0
  local hs = samples/2
  
  return function()
    c = c + 1
    if c == samples then c = 0 end
    if c < hs then
      return amp
    else
      return -amp
    end
  end
end

--Sawtooth
waves[2] = function(samples)
  local c = 0
  local inc = 2/samples
  
  return function()
    c = (c+inc)%2 -1
    return c*amp
  end
end

--Noise
waves[3] = function(samples)
  local c = samples/2
  local v = math.random()
  local flag = flag
  
  return function()
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
      
      if wave and freq then
        gen = waves[wave](math.floor(rate/freq))
      end
      
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
      for i=0,buffer_size-1 do
        sd:setSample(i,gen())
      end
      
      qs:queue(sd)
      qs:play()
    end
  end
  
  love.timer.sleep(sleeptime)
end