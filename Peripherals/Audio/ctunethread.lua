--Chiptune Thread

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
local amp_slide = 0 --How much to increase/decrease the amplitude to reach the target amplitude.
local amp_slide_samples = floor(rate*0.02) --How many samples to reach the wanted amp.
local amp_slide_time = amp_slide_samples/rate --How much time does it take to slide the amp

local wave = 0 --The wave to generate.
local freq = 440 --The frequency to generate the sound at.
local gen --An iterator which generates samples.

local generated_time = 0 --How long the sound has been generated for.

--The waveforms generators list.
local waveforms = {}

--Sin
waveforms[0] = function(samples)
  local r = 0
  
  local hs = samples/2
  local pi = math.pi
  local dpi = pi*2
  
  return function()
    r = (r + pi/hs)%dpi
    
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
  local r = 0
  
  local hs = samples/2
  local pi = math.pi
  local dpi = pi*2
  
  return function()
    r = (r + pi/hs)%dpi
    
    if sin(r) > 0.5 then
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
    
    return (mn(v)*2-1)*2*amp
  end
end

local StartTime = love.timer.getTime() --Start counting the delta time.

--Pull a new command from the channel
local function pullParams()
  if amp > 0 or tamp > 0 then
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
      --New waveform parameters
      local nwave, nfreq, namp = params[1], params[2], params[3]
      nwave, nfreq, namp = nwave or wave, nfreq or 0, namp or 0
      
      if nfreq == 0 then nfreq, namp = freq, 0 end
      
      --The sound generator is already off
      if namp == 0 and amp == 0 then
        break --There's nothing to do
      end
      
      local owave = wave --The old waveform id.
      local ofreq = freq --The old frequency.
      
      --Stop the sound
      if namp == 0 then
        wave = nwave --Incase if the waveform has been changed.
        tamp = 0 --Set the target amplitude to 0 because we want to stop the generator.
        freq = nfreq == 0 and freq or nfreq --The frequency to use while sliding down with the amplitude.
        
        amp_slide = amp/amp_slide_samples --Calculate the amplitude decrease amount each sample.
      else --New waveform to generate.
        wave = nwave --Incase if the waveform has been changed.
        freq = nfreq --Incase if the frequency has been changed.
        tamp = namp --The target amplitude
        
        amp_slide = tamp/amp_slide_samples --Calculate the amplitude increase/decrease amount each sample.
        generated_time = 0
      end
      
      --If the waveform changed, or the frequency changed we will have to create a new generator.
      if owave ~= wave or ofreq ~= freq then
        gen = waveforms[wave](floor(rate/freq)) --The new generator.
      end
      
      --We have to recalculate the buffer size inorder to make sure that each buffer ends with a cycle end.
      if ofreq ~= freq then
        buffer_size = floor(rate/freq) * floor(freq/buffers_rate)
        buffer_time = buffer_size/rate
        buffers_cache = {} --Clear the buffers cache
        buffers_cache_id = 1  --Reset the buffers cache id
      end
    end
  end
  
  local skip_generation = (tamp > 0) and (#buffers_cache == buffers_cache_amount) and (generated_time > max(buffer_time,amp_slide_time)*buffers_cache_amount) and (wave ~= 5)
  
  --Generate audio.
  if amp > 0 or tamp > 0 then
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
      
      if not skip_generation then
      
        local setSample = sounddata.setSample
        
        for i2=0,buffer_size-1 do
          setSample(sounddata,i2,gen())
          
          if tamp > amp then --We have to increase the amplitude.
            amp = min(amp + amp_slide,1)
          elseif tamp < amp then --We have to decrease the amplitude
            amp = max(amp - amp_slide,0)
          end
        end
        
        generated_time = generated_time + buffer_time
        
      end
      
      qs:queue(sounddata) --Insert the new sounddata into the queue.
      qs:play() --Make sure that the QueueableSource is playing.
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