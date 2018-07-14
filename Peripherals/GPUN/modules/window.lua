--GPU: Window and canvas creation.
local Config, GPU, yGPU, GPUKit, DevKit = ...

local events = require("Engine.events")

local RenderKit = GPUKit.Render
local WindowKit = GPUKit.Window

--==Local Variables==--

local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS" or Config._Mobile

local _LIKO_W, _LIKO_H = config._LIKO_W or 192, config._LIKO_H or 128 --LIKO-12 screen dimensions.
local WindowKit.LIKO_X, WindowKit.LIKO_Y = 0,0 --LIKO-12 screen padding in the HOST screen.

local _PixelPerfect = config._PixelPerfect --If the LIKO-12 screen must be scaled pixel perfect.
local WindowKit.LIKOScale = math.floor(config._LIKOScale or 3) --The LIKO12 screen scale to the host screen scale.

WindowKit.width, WindowKit.height = _LIKO_W*WindowKit.LIKOScale, _LIKO_H*WindowKit.LIKOScale --The host window size.
if _Mobile then WindowKit.width, WindowKit.height = 0,0 end

--==Window creation==--

if not love.window.isOpen() then
  love.window.setMode(WindowKit.width,WindowKit.height,{
    vsync = 1,
    resizable = true,
    minwidth = _LIKO_W,
    minheight = _LIKO_H
  })
  
  if config.title then
    love.window.setTitle(config.title)
  else
    love.window.setTitle("LIKO-12 ".._LVERSION)
  end
  love.window.setIcon(love.image.newImageData("icon.png"))
end

--Incase if the host operating system decided to give us different window dimensions.
WindowKit.width, WindowKit.height = love.graphics.getDimensions()

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
  WindowKit.width, WindowKit.height = w, h
  local TSX, TSY = w/_LIKO_W, h/_LIKO_H --TestScaleX, TestScaleY
  
  WindowKit.LIKOScale = (TSX < TSY) and TSX or TSY
  if _PixelPerfect then WindowKit.LIKOScale = math.floor(WindowKit.LIKOScale) end
  
  WindowKit.LIKO_X, WindowKit.LIKO_Y = (WindowKit.width-_LIKO_W*WindowKit.LIKOScale)/2, (WindowKit.height-_LIKO_H*WindowKit.LIKOScale)/2
  if _Mobile then WindowKit.LIKO_Y, RenderKit.AlwaysDrawTimer = 0, 1 end
  
  RenderKit.ShouldDraw = true
end)

--Hook to some functions to redraw (when the window is moved, got focus, etc ...)
events.register("love:focus",function(f) if f then RenderKit.ShouldDraw = true end end) --Window got focus.
events.register("love:visible",function(v) if v then RenderKit.ShouldDraw = true end end) --Window got visible.

--==GPUKit Output==--
WindowKit.LIKO_W, WindowKit.LIKO_H = _LIKO_W, _LIKO_H