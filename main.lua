io.stdout:setvbuf("no") --For console output to work instantly.
local reboot, events = false

--==Contribution Guide==--
--[[
I did create an events system for LIKO-12, making my work more modular.
Below there is a modified love.run function which implements 4 things:
- Instead of calling love callbacks, it triggers the events with name "love:callback", for ex: "love:mousepressed".
- It contains a small and a nice trick which reloads all the code files (expect main.lua & conf.lua)
    then reboots LIKO-12 without haveing to restart love.
- When the love.graphics is active (usable) it triggers "love:graphics" event.
- If any "love:quit" event returned true, the quit will be canceled.

About the soft restart:
* To do a soft restart trigger the "love:reboot" event, you can pass custom args for love.load to get after reboot.
* This works by clearing package.loaded expect native libraries, calling love.graphics.reset(),
    reseting the events library, and finally restarts love.run from the top.
* In case you changed something in main.lua or conf.lua, you can do a hard restart by calling love.event.quit("restart")
* In DiskOS you can run 'reboot' command to do a soft reboot, or 'reboot hard' to do a hard one (by restarting love).

I don't think anyone would want to edit anything in this file.

==Contributors to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

local package_exceptions = {
  "bit", "utf8", "ffi", --LuaJIT
  "ssl.core", "ssl.context", "ssl.x209", "ssl", "https", --LuaSec
  "socket.http", "ltn12", "mime", "socket.smtp", "socket", "socket.url" --LuaSocket
}

for k,v in ipairs(package_exceptions) do package_exceptions[v] = k end

love.filesystem.load("Engine/errhand.lua")() --Apply the custom error handler.

--Internal Callbacks--
function love.load()
  love.filesystem.load("BIOS/init.lua")() --Initialize the BIOS.
  events.trigger("love:load")
end

function love.run()
  local loadArg = {love.arg.parseGameArguments(arg), arg}
  
  local dt = 0
  
  local function runReset()
    events = require("Engine.events")
    events.register("love:reboot",function(args) --Code can trigger this event to do a soft restart.
      args = args or {}
      reboot = {love.arg.parseGameArguments(args),args}
    end)

    if love.load then love.load(reboot or loadArg) end reboot = false

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    dt = 0
  end

  runReset() --Reset for the first time

  return function()
    -- Process events.
    if love.event then
      local canvas = love.graphics.getCanvas()
      if canvas then love.graphics.setCanvas() end
      love.event.pump()
      if canvas then love.graphics.setCanvas{canvas,stencil=true} end
      
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          local r = events.triggerWithReturns("love:quit")
          --If any event returns true the quit will be cancelled
          for k=1, #r do
            if r[k][1] then r = nil break end
          end
          if r then return a or 0 end
        else
          events.trigger("love:"..name,a,b,c,d,e,f)
        end
      end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then
      dt = love.timer.step()
    end

    -- Call update and draw
    events.trigger("love:update",dt) -- will pass 0 if love.timer is disabled

    if love.graphics and love.graphics.isActive() then
      events.trigger("love:graphics")
    end
    
    if love.timer then love.timer.sleep(0.001) end

    if reboot then
      for k in pairs(package.loaded) do
        if not package_exceptions[k] then package.loaded[k] = nil end
      end--Reset the required packages

      love.graphics.reset() --Reset the GPU
      events = nil --Must undefine this.
      runReset() --Reset
    end
  end
end
