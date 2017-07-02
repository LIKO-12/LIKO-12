io.stdout:setvbuf("no")
local reboot, events = false

--==Contribution Guide==--
--[[
I did create an events system for liko12, making my work more modular.
Below there is a modified love.run function which implements 4 things:
- Instead of calling love callbacks, it triggers the events with name "love:callback", for ex: "love:mousepressed".
- It contains a small and a nice trick which reloads all the code files (expect main.lua & conf.lua) and reboots liko12 without haveing to restart love.
- When the love.graphics is active (usable) it triggers "love:graphics" event.
- If any "love:quit" event returned true, the quit will be canceled.

About the soft restart:
* To do a soft restart trigger the "love:reboot" event.
* This works by clearing package.loaded expect bit library, then calling love.graphics.reset(), and reseting the events library, and finally restarts love.run from the top (there's an extra while loop you can see).
* In case you changed something in main.lua or conf.lua then you can do a hard restart by calling love.event.quit("restart")
* In DiskOS you can run 'reboot' command to do a soft reboot, or 'reboot hard' to do a hard one (by restarting love).

I don't think anyone would want to edit anything in this file.

==Contributers to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

love.filesystem.load("Engine/errhand.lua")() --Apply the custom error handler.

--Internal Callbacks--
function love.load(args)
  love.filesystem.load("BIOS/init.lua")() --Initialize the BIOS.
  events:trigger("love:load")
end

function love.run(arg)
  while true do
    events = require("Engine.events")
    events:register("love:reboot",function(args) --Code can trigger this event to do a soft restart.
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
            local r = events:trigger("love:quit") --If any event returns true the quit will be cancelled
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
          if k ~= "bit" and k ~= "ffi" then package.loaded[k] = nil end
        end--Reset the required packages
        
        love.graphics.reset() --Reset the GPU
        events = nil --Must undefine this.
        break --Break our game loop
      end
    end
  end
end