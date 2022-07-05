--Chiptune SFX Thread

require("love.system")

--Are we running on mobile ?
local onMobile = (love.system.getOS() == "Android")

--Store math functions in locals to optamize speed.
local min, max, floor, sin, abs, random = math.min, math.max, math.floor, math.sin, math.abs, math.random

--The chunnel to recieve orders from
local chIn = ...

--Require love modules
require("love.audio")
require("love.sound")
require("love.timer")
require("love.math")

local bitdepth = 8 --Bits per sample (8 or 16)
local rate = onMobile and 22050 or 44100 --The samples rate.
local buffers_rate = 20 --The number of buffers created each second.

local buffer_size = rate/buffers_rate --The size of sounddatas generated and inserted to the QueueableSource
local buffer_time = buffer_size/rate --The time of the buffer in seconds, used when putting the thread into sleep.

local buffers_cache = {} --Put in the sounddatas
local buffers_cache_id = 1 --The current active sounddata from the cache
local buffers_cache_amount = onMobile and 4 or 2 --The number of sounddatas to create

--Create a new QueueableSource, with 2 buffer slots.
local qs = love.audio.newQueueableSource(rate,bitdepth,1,buffers_cache_amount)

local amp = 0 --The soundwave cycle amplitude.
local tamp = 0 --The target amplitude.
local amp_slide_samples = floor(rate*0.02) --How many samples to reach the wanted amp.
--local amp_slide_time = amp_slide_samples/rate --How much time does it take to slide the amp
local amp_slide = 1/amp_slide_samples --How much to increase/decrease the amplitude to reach the target amplitude.

local wave = 0 --The wave to generate.
--local freq = 440 --The frequency to generate the sound at.
local gen --An iterator which generates samples.

local sfxdata = {} --The list of waves to play and for how long.
local samplesToNextWave = 0

--The waveforms generators list.
local waveforms = {}

--No sound
waveforms[-1] = function(samples)
  return function()
    return 0
  end
end

--Sin
waveforms[0] = function(samples)
  local r = 0
  
  local hs = samples/2
  local pi = math.pi
  local dpi = pi*2
  
  return function()
    r = r + pi/hs
    
    if r >= dpi then
      r = r - dpi
    end
    
    return sin(r)*amp
  end
end

--Square
waveforms[1] = function(samples)
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
waveforms[2] = function(samples)
  local c = 0
  local qsp = samples/4
  
  return function()
    c = c + 1
    if c == samples then c = 0 end
    if c < qsp then
      return amp
    else
      return -amp
    end
  end
end

--Sawtooth
waveforms[3] = function(samples)
  local c = 0
  local inc = 2/samples
  
  return function()
    c = (c+inc)%2
    return (c-1)*amp
  end
end

--Triangle
waveforms[4] = function(samples)
  local inc = 4/samples
  local c = 3
  
  return function()
    c = (c+inc)%4
    return (abs(c-2)-1)*amp
  end
end

--Noise
waveforms[5] = function(samples)
  local v = random()
  local hs = floor(samples/2)
  local c = hs
  
  local mn = love.math.noise
  
  return function()
    c = c - 1
    if c == 0 then
      v = random()
      c = hs
    end
    
    return (v*2-1)*2*amp
  end
end

local wavepos = -3
local function nextWave()
  wavepos = wavepos + 4
  
  local ntime = sfxdata[wavepos]
  local nwave = sfxdata[wavepos+1]
  local nfreq = sfxdata[wavepos+2]
  local namp = sfxdata[wavepos+3]
  
  if ntime then
    samplesToNextWave = ntime
  else
    samplesToNextWave = buffer_size
    wave = -1
    tamp = 0
    return
  end
  
  if nwave == -1 then --No sound
    tamp = 0 --Set the target amplitude to 0 because we want to stop the generator.
  else --New wave
    gen = waveforms[nwave](nfreq)
    wave = nwave
    --freq = nfreq
    tamp = namp
  end
end

local StartTime = love.timer.getTime() --Start counting the delta time.

--Pull a new command from the channel
local function pullParams()
  if gen then
    return chIn:pop()
  else
    local arg = chIn:demand()
    StartTime = love.timer.getTime() --Don't count the time spent while waiting for a new command.
    return arg
  end
end

--The thread while true do loop !
while true do
  --Check for new commands
  for params in pullParams do
    if type(params) == "string" and params == "stop" then
      return --It's time to shutdown the thread.
    else
      --Convert the frequency from Hz to samples per cycle.
      for i=3,#params,4 do
        if params[i-1] == -1 then
          params[i] = 1
        else
          params[i] = floor(rate/params[i])
        end
      end
      
      --Convert the time from seconds to samples, and make sure it ends with a cycle end.
      for i=1,#params,4 do
        local samples = floor(params[i]*rate)
        local freq = params[i+2]
        params[i] = max(floor(samples/freq+0.5)*freq,1)
      end
      
      sfxdata = params
      wavepos = -3
      nextWave()
    end
  end
  
  --Generate audio.
  if gen then
    --If there're any free buffer slots, then we have to fill it.
    for i=1, qs:getFreeBufferCount() do
      
      local sounddata --The sounddata to work on.
      
      --Get the sounddata out from the buffers cache.
      if #buffers_cache == buffers_cache_amount then
        sounddata = buffers_cache[ buffers_cache_id ]
      else
        sounddata = love.sound.newSoundData(buffer_size, rate, bitdepth, 1)
        buffers_cache[ buffers_cache_id ] = sounddata
      end
      
      buffers_cache_id = buffers_cache_id + 1 --Increase the id
      if buffers_cache_id > buffers_cache_amount then buffers_cache_id = 1 end
      
      local setSample = sounddata.setSample
      
      local sfxEnd = false
      
      for i2=0,buffer_size-1 do
        setSample(sounddata,i2,gen())
        
        samplesToNextWave = samplesToNextWave - 1
        
        if samplesToNextWave == 0 then
          nextWave()
          
          if wave == -1 then
            sfxEnd = true
          end
        end
        
        if tamp > amp then --We have to increase the amplitude.
          amp = min(amp + amp_slide,1)
        elseif tamp < amp then --We have to decrease the amplitude
          amp = max(amp - amp_slide,0)
        end
      end
      
      qs:queue(sounddata) --Insert the new sounddata into the queue.
      qs:play() --Make sure that the QueueableSource is playing.
      
      if sfxEnd then
        gen = nil
        break
      end
    end
  end
  
  local EndTime = love.timer.getTime() --Calculate the time spent while generating.
  
  local dt = EndTime-StartTime
  
  StartTime = EndTime
  
  local sleeptime = (buffer_time - dt*2)*0.6 --Calculate the remaining time that we can sleep.
  
  --There's time to sleep
  if sleeptime > 0 then
    love.timer.sleep(sleeptime) --ZzZzZzZzZzZzZzZzZzzzz.
    StartTime = love.timer.getTime() --Skip the time spent while sleeping..
    
  else --Well, we're not generating enough
    
    --TODO: Lower the sample rate.
    
  end
  
  --REPEAT !
end
