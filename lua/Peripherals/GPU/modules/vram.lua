--GPU: Video Ram.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local Path = GPUVars.Path
local RenderVars = GPUVars.Render
local WindowVars = GPUVars.Window
local CalibrationVars = GPUVars.Calibration
local VRamVars = GPUVars.VRam

--==Varss Constants==--
local _LIKO_W, _LIKO_H = WindowVars.LIKO_W, WindowVars.LIKO_H
local ofs = CalibrationVars.Offsets

--==Local Variables==--

local newImageHandler = love.filesystem.load(Path.."scripts/imageHandler.lua")
local VRAMBound = false
local VRAMImg
local VRAMDrawImg

--==VRAM==--

local function BindVRAM()
  if VRAMBound then return end
  love.graphics.setCanvas()
  VRAMImg = RenderVars.ScreenCanvas:newImageData()
  love.graphics.setCanvas{RenderVars.ScreenCanvas,stencil=true}
  VRAMBound = true
end

local function UnbindVRAM(keepbind)
  if not VRAMBound then return end
  if VRAMDrawImg then
    VRAMDrawImg:replacePixels(VRAMImg)
  else
    VRAMDrawImg = love.graphics.newImage(VRAMImg)
  end
  GPU.pushColor()
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setColor(1,1,1,1)
  love.graphics.setShader()
  love.graphics.clear(0,0,0,1)
  love.graphics.draw(VRAMDrawImg,ofs.image[1],ofs.image[2])
  love.graphics.setShader(RenderVars.DrawShader)
  love.graphics.pop()
  GPU.popColor()
  if not keepbind then
    VRAMBound = false
    VRAMImg = nil
  end
end

local VRAMHandler; VRAMHandler = newImageHandler(_LIKO_W,_LIKO_H,function()
  RenderVars.ShouldDraw = true
end,function()
  BindVRAM()
  VRAMHandler("setImage",0,0,VRAMImg)
end)

--==GPUVars Exports==--
VRamVars.BindVRAM = BindVRAM
VRamVars.UnbindVRAM = UnbindVRAM

--==DevKit Exports==--
DevKit.VRAMHandler = VRAMHandler