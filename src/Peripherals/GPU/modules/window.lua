--GPU: Window and canvas creation.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local events = require("Engine.events")

local RenderVars = GPUVars.Render
local WindowVars = GPUVars.Window

--==Localized Lua Library==--

local mathFloor = math.floor

--==Local Variables==--

local CPUKit = Config.CPUKit

local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS" or Config._Mobile

local _LIKO_W, _LIKO_H = Config._LIKO_W or 192, Config._LIKO_H or 128 --LIKO-12 screen dimensions.
WindowVars.LIKO_X, WindowVars.LIKO_Y = 0,0 --LIKO-12 screen padding in the HOST screen.

local _PixelPerfect = Config._PixelPerfect --If the LIKO-12 screen must be scaled pixel perfect.
WindowVars.LIKOScale = mathFloor(Config._LIKOScale or 3) --The LIKO12 screen scale to the host screen scale.

WindowVars.Width, WindowVars.Height = _LIKO_W*WindowVars.LIKOScale, _LIKO_H*WindowVars.LIKOScale --The host window size.
if _Mobile then WindowVars.Width, WindowVars.Height = 0,0 end

--==Window creation==--

if not love.window.isOpen() then
  love.window.setMode(WindowVars.Width,WindowVars.Height,{
    vsync = 1,
    resizable = true,
    fullscreen = _Mobile,
    minwidth = _LIKO_W,
    minheight = _LIKO_H
  })
  
  if Config.title then
    love.window.setTitle(Config.title)
  else
    love.window.setTitle("LIKO-12 ".._LVERSION)
  end
  love.window.setIcon(love.image.newImageData("icon.png"))
end

--Incase if the host operating system decided to give us different window dimensions, or if the mobile device has a notch
WindowVars.LIKO_X, WindowVars.LIKO_Y, WindowVars.Width, WindowVars.Height = love.window.getSafeArea()

--==Window termination==--

events.register("love:quit", function()
  if love.window.isOpen() then
    love.graphics.setCanvas()
    love.window.close()
  end
  return false
end)

--==Window Events==--

--Hook the resize function
events.register("love:resize",function(w,h) --Do some calculations
  local SafeX, SafeY, SafeW, SafeH = love.window.getSafeArea()

  WindowVars.Width, WindowVars.Height = SafeW, SafeH
  local TSX, TSY = w/_LIKO_W, h/_LIKO_H --TestScaleX, TestScaleY
  
  WindowVars.LIKOScale = (TSX < TSY) and TSX or TSY
  if _PixelPerfect then WindowVars.LIKOScale = mathFloor(WindowVars.LIKOScale) end
  
  WindowVars.LIKO_X, WindowVars.LIKO_Y = SafeX + (WindowVars.Width-_LIKO_W*WindowVars.LIKOScale)/2, SafeY + (WindowVars.Height-_LIKO_H*WindowVars.LIKOScale)/2
  if _Mobile then WindowVars.LIKO_Y, RenderVars.AlwaysDrawTimer = SafeY, 1 end
  
  RenderVars.ShouldDraw = true
end)

--Hook to some functions to redraw (when the window is moved, got focus, etc ...)
events.register("love:focus",function(f) if f then RenderVars.ShouldDraw = true end end) --Window got focus.
events.register("love:visible",function(v) if v then RenderVars.ShouldDraw = true end end) --Window got visible.

--File drop hook
events.register("love:filedropped", function(file)
  file:open("r")
  local data = file:read()
  file:close()
  if CPUKit then CPUKit.triggerEvent("filedropped",file:getFilename(),data) end
end)

--Alt-Return (Fullscreen toggle) hook
local raltDown, lastWidth, lastHeight = false, 0, 0

events.register("love:keypressed", function(key, scancode,isrepeat)
  if key == "ralt" then
    raltDown = true --Had to use a workaround, for some reason isDown("ralt") is not working at Rami's laptop
  elseif key == "return" and raltDown and not isrepeat then
    local screenshot = GPU.screenshot():image()

    local canvas = love.graphics.getCanvas() --Backup the canvas.
    love.graphics.setCanvas() --Deactivate the canvas.

    if love.window.getFullscreen() then --Go windowed
      love.window.setMode(lastWidth,lastHeight,{
        fullscreen = false,
        vsync = 1,
        resizable = true,
        minwidth = _LIKO_W,
        minheight = _LIKO_H
      })
    else --Go fullscreen
      lastWidth, lastHeight = love.window.getMode()
      love.window.setMode(0,0,{fullscreen=true})
    end

    events.trigger("love:resize", love.graphics.getDimensions()) --Make sure the canvas is scaled correctly
    love.graphics.setCanvas{canvas,stencil=true} --Reactivate the canvas.

    screenshot:draw() --Restore the backed up screenshot
  end
end)

events.register("love:keyreleased", function(key, scancode)
  if key == "ralt" then raltDown = false end
end)

--==Graphics Initializations==--
love.graphics.clear(0,0,0,1) --Clear the host screen.

events.trigger("love:resize", WindowVars.Width, WindowVars.Height) --Calculate LIKO12 scale to the host window for the first time.

--==GPU Window API==--
function GPU.screenSize() return _LIKO_W, _LIKO_H end
function GPU.screenWidth() return _LIKO_W end
function GPU.screenHeight() return _LIKO_H end

--==Helper functions for WindowVars==--
function WindowVars.HostToLiko(x,y) --Convert a position from HOST screen to LIKO12 screen.
  return mathFloor((x - WindowVars.LIKO_X)/WindowVars.LIKOScale), mathFloor((y - WindowVars.LIKO_Y)/WindowVars.LIKOScale)
end

function WindowVars.LikoToHost(x,y) --Convert a position from LIKO12 screen to HOST
  return mathFloor(x*WindowVars.LIKOScale + WindowVars.LIKO_X), mathFloor(y*WindowVars.LIKOScale + WindowVars.LIKO_Y)
end

--==GPUVars Exports==--
WindowVars.LIKO_W, WindowVars.LIKO_H = _LIKO_W, _LIKO_H

--==DevKit Exports==--
DevKit._LIKO_W = _LIKO_W
DevKit._LIKO_H = _LIKO_H
function DevKit.DevKitDraw(bool)
  RenderVars.DevKitDraw = bool
end