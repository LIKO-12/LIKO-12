io.stdout:setvbuf("no")
local reboot, events = false

--Internal Callbacks--
function love.load(args)
  love.filesystem.load("BIOS/init.lua")() --Initialize the BIOS.
  events:trigger("love:load")
end

function love.run(arg)
  while true do
    events = require("Engine.events")
    events:register("love:reboot",function(args)
      --events:trigger("love:rebooting",args)
      reboot = args or {}
    end)
   
    if love.math then
      love.math.setRandomSeed(os.time())
    end
   
    if love.load then love.load(reboot or arg) end reboot = false
   
    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end
   
    local dt = 0
   
    -- Main loop time.
    while true do
      -- Process events.
      if love.event then
        love.event.pump()
        for name, a,b,c,d,e,f in love.event.poll() do
          if name == "quit" then
            local r = events:trigger("love:quit")
            for k,v in pairs(r) do
              if v and v[1] then r = nil break end
            end
            if r then return a end
          else
            events:trigger("love:"..name,a,b,c,d,e,f)
          end
        end
      end
   
      -- Update dt, as we'll be passing it to update
      if love.timer then
        love.timer.step()
        dt = love.timer.getDelta()
      end
   
      -- Call update and draw
      events:trigger("love:update",dt) -- will pass 0 if love.timer is disabled
    
      if love.graphics and love.graphics.isActive() then
        events:trigger("love:graphics")
      end
    
      if love.timer then love.timer.sleep(0.001) end
      
      if reboot then
        for k,v in pairs(package.loaded) do
          if k ~= "bit" then package.loaded[k] = nil end
        end--Reset the required packages
        
        events = nil --Must undefine this.
        break --Break our game loop
      end
    end
  end
end