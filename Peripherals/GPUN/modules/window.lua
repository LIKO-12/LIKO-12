--GPU: Window and canvas creation.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local events = require("Engine.events")

local RenderKit = GPUKit.Render
local WindowKit = GPUKit.Window

--==Localized Lua Library==--

local mathFloor = math.floor

--==Local Variables==--

local CPUKit = Config.CPUKit

local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS" or Config._Mobile

local _LIKO_W, _LIKO_H = Config._LIKO_W or 192, Config._LIKO_H or 128 --LIKO-12 screen dimensions.
WindowKit.LIKO_X, WindowKit.LIKO_Y = 0,0 --LIKO-12 screen padding in the HOST screen.

local _PixelPerfect = Config._PixelPerfect --If the LIKO-12 screen must be scaled pixel perfect.
WindowKit.LIKOScale = mathFloor(Config._LIKOScale or 3) --The LIKO12 screen scale to the host screen scale.

WindowKit.Width, WindowKit.Height = _LIKO_W*WindowKit.LIKOScale, _LIKO_H*WindowKit.LIKOScale --The host window size.
if _Mobile then WindowKit.Width, WindowKit.Height = 0,0 end

--==Window creation==--

if not love.window.isOpen() then
  love.window.setMode(WindowKit.Width,WindowKit.Height,{
    vsync = 1,
    resizable = true,
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

--Incase if the host operating system decided to give us different window dimensions.
WindowKit.Width, WindowKit.Height = love.graphics.getDimensions()

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
  WindowKit.Width, WindowKit.Height = w, h
  local TSX, TSY = w/_LIKO_W, h/_LIKO_H --TestScaleX, TestScaleY
  
  WindowKit.LIKOScale = (TSX < TSY) and TSX or TSY
  if _PixelPerfect then WindowKit.LIKOScale = mathFloor(WindowKit.LIKOScale) end
  
  WindowKit.LIKO_X, WindowKit.LIKO_Y = (WindowKit.Width-_LIKO_W*WindowKit.LIKOScale)/2, (WindowKit.Height-_LIKO_H*WindowKit.LIKOScale)/2
  if _Mobile then WindowKit.LIKO_Y, RenderKit.AlwaysDrawTimer = 0, 1 end
  
  RenderKit.ShouldDraw = true
end)

--Hook to some functions to redraw (when the window is moved, got focus, etc ...)
events.register("love:focus",function(f) if f then RenderKit.ShouldDraw = true end end) --Window got focus.
events.register("love:visible",function(v) if v then RenderKit.ShouldDraw = true end end) --Window got visible.

--File drop hook
events.register("love:filedropped", function(file)
  file:open("r")
  local data = file:read()
  file:close()
  if CPUKit then CPUKit.triggerEvent("filedropped",file:getFilename(),data) end
end)

--==Graphics Initializations==--
love.graphics.clear(0,0,0,1) --Clear the host screen.

events.trigger("love:resize", WindowKit.HOST_W, WindowKit.HOST_H) --Calculate LIKO12 scale to the host window for the first time.

--==GPU Window API==--
function GPU.screenSize() return _LIKO_W, _LIKO_H end
function GPU.screenWidth() return _LIKO_W end
function GPU.screenHeight() return _LIKO_H end

--==Helper functions for WindowKit==--
function WindowKit.HostToLiko(x,y) --Convert a position from HOST screen to LIKO12 screen.
  return mathFloor((x - WindowKit.LIKO_X)/WindowKit.LIKOScale), mathFloor((y - WindowKit.LIKO_Y)/WindowKit.LIKOScale)
end

function WindowKit.LikoToHost(x,y) --Convert a position from LIKO12 screen to HOST
  return mathFloor(x*WindowKit.LIKOScale + WindowKit.LIKO_X), mathFloor(y*WindowKit.LIKOScale + WindowKit.LIKO_Y)
end

--==GPUKit Exports==--
WindowKit.LIKO_W, WindowKit.LIKO_H = _LIKO_W, _LIKO_H