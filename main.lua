io.stdout:setvbuf("no")

function love.mousepressed(x,y,button,istouch)
  
end

function love.mousemoved(x,y,dx,dy,istouch)
  
end

function love.mousereleased(x,y,button,istouch)
  
end

function love.wheelmoved(x,y)
  
end

function love.touchpressed(id,x,y,dx,dy,pressure)
  
end

function love.touchmoved(id,x,y,dx,dy,pressure)
  
end

function love.touchreleased(id,x,y,dx,dy,pressure)
  
end

function love.keypressed(key,scancode,isrepeat)
  
end

function love.keyreleased(key,scancode)
  
end

function love.textinput(text)
  
end

--Internal Callbacks--
function love.load()
  
end

function love.resize(w,h)
  
end

function love.update(dt)
  
end

function love.visible(v)
  
end

function love.focus(f)
  
end

function love.run()
 
	if love.math then
		love.math.setRandomSeed(os.time())
	end
 
	if love.load then love.load(arg) end
 
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
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end
 
		-- Call update and draw
		if love.update then
    love.update(dt) -- will pass 0 if love.timer is disabled
  end
  
  if love.graphics and love.graphics.isActive() then
    
  end
  
		if love.timer then love.timer.sleep(0.001) end
	end
end