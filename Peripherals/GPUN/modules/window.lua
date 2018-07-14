--GPU: Window and canvas creation.
local Config, GPU, yGPU, GPUKit, DevKit = ...

local events = require("Engine.events")

--==Local Variables==--

local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

local _LIKO_W, _LIKO_H = config._LIKO_W or 192, config._LIKO_H or 128 --LIKO-12 screen dimensions.
local _LIKO_X, _LIKO_Y = 0,0 --LIKO-12 screen padding in the HOST screen.

local _PixelPerfect = config._PixelPerfect --If the LIKO-12 screen must be scaled pixel perfect.
local _LIKOScale = math.floor(config._LIKOScale or 3) --The LIKO12 screen scale to the host screen scale.

local _HOST_W, _HOST_H = _LIKO_W*_LIKOScale, _LIKO_H*_LIKOScale --The host window size.
if _Mobile then _HOST_W, _HOST_H = 0,0 end

--==Window creation==--

if not love.window.isOpen() then
  love.window.setMode(_HOST_W,_HOST_H,{
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

--==Window termination==--

events.register("love:quit", function()
  if love.window.isOpen() then
    love.graphics.setCanvas()
    love.window.close()
  end
  return false
end)

--Incase if the host operating system decided to give us different window dimensions.
_HOST_W, _HOST_H = love.graphics.getDimensions()

--==GPUKit Output==--
do
  local WindowKit = {}
  
  
  
  GPUKit.Window = WindowKit
end