local chIn = ...

require("love.audio")
require("love.sound")
require("love.timer")
require("love.system")

local json = require("Engine.JSON")

local sfxr = require("Peripherals.Audio.sfxr")
local QSource = require("Peripherals.Audio.QueueableSource")

--2 Channels
local sfx1 = sfxr.newSound()
local sfx2 = sfxr.newSound()

local qs1 = QSource:new()
local qs2 = QSource:new()

local sfx1_count = false
local sfx2_count = false

local sfx1_iter = false
local sfx2_iter = false

local onMobile = (love.system.getOS() == "Android")

local rate = onMobile and 22050 or 44100

local buffer_size = rate/4
local buffer_time = buffer_size/rate

local function popJob()
  if sfx1_count or sfx2_count then
    return chIn:pop()
  else
    local arg = chIn:demand()
    love.timer.step()
    return arg
  end
end

love.timer.step()

while true do
  for newJob in popJob do
    if type(newJob) == "string" and newJob == "stop" then return end
    if newJob.channel == 1 then
      local params = json:decode(newJob.params)
      for k1,v1 in pairs(params) do
        if type(v1) == "table" then
          for k2,v2 in pairs(v1) do
            sfx1[k1][k2]= v2
          end
        else
          sfx1[k1] = v1
        end
      end
      
      qs1:clear()
      sfx1_count = sfx1:getEnvelopeLimit(rate)
      sfx1_iter = sfx1:generate(rate)
    elseif newJob.channel == 2 then
      local params = json:decode(newJob.params)
      for k1,v1 in pairs(params) do
        if type(v1) == "table" then
          for k2,v2 in pairs(v1) do
            sfx2[k1][k2]= v2
          end
        else
          sfx2[k1] = v1
        end
      end
      
      qs2:clear()
      sfx2_count = sfx2:getEnvelopeLimit(rate)
      sfx2_iter = sfx2:generate(rate)
    end
  end
  
  --Generate sfx1
  if sfx1_count then
    qs1:step()
    
    if qs1:getFreeBufferCount() > 0 then
      local buffer_size = buffer_size
      
      --If it's the last sample
      if sfx1_count < buffer_size then
        buffer_size = sfx1_count
        sfx1_count = false
      else
        sfx1_count = sfx1_count - buffer_size
      end
      
      local buffer = love.sound.newSoundData(buffer_size, rate, 16, 1)
      local setSample = buffer.setSample
      for i=0, buffer_size-1 do
        setSample(buffer,i,sfx1_iter())
      end
      
      qs1:queue(buffer)
      qs1:play()
    end
  end
  
  --Generate sfx2
  if sfx2_count then
    qs2:step()
    
    if qs2:getFreeBufferCount() > 0 then
      local buffer_size = buffer_size
      
      --If it's the last sample
      if sfx2_count < buffer_size then
        buffer_size = sfx2_count
        sfx2_count = false
      else
        sfx2_count = sfx2_count - buffer_size
      end
      
      local buffer = love.sound.newSoundData(buffer_size, rate, 16, 1)
      local setSample = buffer.setSample
      for i=0, buffer_size-1 do
        setSample(buffer,i,sfx2_iter())
      end
      
      qs2:queue(buffer)
      qs2:play()
    end
  end
  
  love.timer.step()
  local dt = love.timer.getDelta()
  local active = (sfx1_count and 1 or 0) + (sfx2_count and 1 or 0)
  local st = (buffer_time - dt*2*active)*0.9
  
  if st > 0.01 then
    love.timer.sleep(st)
    love.timer.step()
  end
end