--GPU: Screenshot and Label image.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local lg = love.graphics

local events = require("Engine.events")

local Path = GPUVars.Path
local MiscVars = GPUVars.Misc
local WindowVars = GPUVars.Window
local RenderVars = GPUVars.Render
local SharedVars = GPUVars.Shared

--==Varss Constants==--
local _LIKO_W, _LIKO_H = WindowVars.LIKO_W, WindowVars.LIKO_H
local systemMessage = MiscVars.systemMessage
local Verify = SharedVars.Verify

--==Local Variables==--

local _ScreenshotKey = Config._ScreenshotKey or "f5"
local _ScreenshotScale = Config._ScreenshotScale or 3

local _LabelCaptureKey = Config._LabelCaptureKey or "f6"

--==GPU Screenshot API==--

function GPU.screenshot(x,y,w,h)
  x, y, w, h = x or 0, y or 0, w or _LIKO_W, h or _LIKO_H
  x = Verify(x,"X","number",true)
  y = Verify(y,"Y","number",true)
  w = Verify(w,"W","number",true)
  h = Verify(h,"H","number",true)
  lg.setCanvas()
  local imgdata = GPU.imagedata(RenderVars.ScreenCanvas:newImageData(1,1,x,y,w,h))
  lg.setCanvas{RenderVars.ScreenCanvas,stencil=true}
  return imgdata
end

--==Label Image==--

local newImageHandler = love.filesystem.load(Path.."scripts/imageHandler.lua")

local LabelImage = love.image.newImageData(_LIKO_W, _LIKO_H)

LabelImage:mapPixel(function() return 0,0,0,1 end)

local LIMGHandler; LIMGHandler = newImageHandler(_LIKO_W,_LIKO_H,function() end,function() end)

LIMGHandler("setImage",0,0,LabelImage)

--==Label Image API==--

function GPU.getLabelImage()
  return GPU.imagedata(LabelImage)
end

--==Hooks==--

--Screenshot and LabelCapture keys handling.
events.register("love:keypressed", function(key)
  if key == _ScreenshotKey then
    local sc = GPU.screenshot()
    sc = sc:enlarge(_ScreenshotScale)
    local png = sc:exportOpaque()
    love.filesystem.write("/Screenshots/LIKO12-"..os.time()..".png",png)
    systemMessage("Screenshot has been taken successfully",2)
  elseif key == _LabelCaptureKey then
    lg.setCanvas()
    LabelImage:paste(RenderVars.ScreenCanvas:newImageData(),0,0,0,0,_LIKO_W,_LIKO_H)
    lg.setCanvas{RenderVars.ScreenCanvas,stencil=true}
    systemMessage("Captured label image successfully !",2)
  end
end)

--==DevKit Exports==--
DevKit.LIMGHandler = LIMGHandler
DevKit.LabelImage = LabelImage