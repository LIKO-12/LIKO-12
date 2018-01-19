--Chiptune Thread

local chIn = ...

require("love.audio")
require("love.sound")
require("love.timer")
require("love.math")

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
  local dpi = pi*2
  
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

--Pulse
waves[2] = function(samples)
  local r = 0
  
  local hs = samples/2
  local pi = math.pi
  local dpi = pi*2
  
  return function()
    r = (r + pi/hs)%dpi
    
    if math.sin(r) > 0.5 then
      return amp
    else
      return -amp
    end
  end
end

--Sawtooth
waves[3] = function(samples)
  local c = 0
  local inc = 2/samples
  
  return function()
    c = (c+inc)%2
    return (c-1)*amp
  end
end

--Triangle
waves[4] = function(samples)
  local abs = math.abs
  local c = 0
  local inc = 4/samples
  
  return function()
    c = (c+inc)%4
    return (abs(c-2)-1)*amp
  end
end

--Noise
waves[5] = function(samples)
  local v = math.random()
  local hs = math.floor(samples/2)
  local c = hs
  
  local mn = love.math.noise
  
  return function()
    c = c - 1
    if c == 0 then
      v = math.random()
      c = hs
    end
    
    return (mn(v)*2-1)*2
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
      
      if freq == 0 or amp == 0 then
        wave, freq, amp = false, false, false
      end
      
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