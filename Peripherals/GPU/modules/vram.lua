--GPU: Video Ram.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local Path = GPUKit.Path
local RenderKit = GPUKit.Render
local WindowKit = GPUKit.Window
local CalibrationKit = GPUKit.Calibration
local VRamKit = GPUKit.VRam

--==Kits Constants==--
local _LIKO_W, _LIKO_H = WindowKit.LIKO_W, WindowKit.LIKO_H
local ofs = CalibrationKit.Offsets

--==Local Variables==--

local newImageHandler = love.filesystem.load(Path.."scripts/imageHandler.lua")
local VRAMBound = false
local VRAMImg

--==VRAM==--

local function BindVRAM()
  if VRAMBound then return end
  love.graphics.setCanvas()
  VRAMImg = RenderKit.ScreenCanvas:newImageData()
  love.graphics.setCanvas{RenderKit.ScreenCanvas,stencil=true}
  VRAMBound = true
end

local function UnbindVRAM(keepbind)
  if not VRAMBound then return end
  local Img = love.graphics.newImage(VRAMImg)
  GPU.pushColor()
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setColor(1,1,1,1)
  love.graphics.setShader()
  love.graphics.clear(0,0,0,1)
  love.graphics.draw(Img,ofs.image[1],ofs.image[2])
  love.graphics.setShader(RenderKit.DrawShader)
  love.graphics.pop()
  GPU.popColor()
  if not keepbind then
    VRAMBound = false
    VRAMImg = nil
  end
end

local VRAMHandler; VRAMHandler = newImageHandler(_LIKO_W,_LIKO_H,function()
  RenderKit.ShouldDraw = true
end,function()
  BindVRAM()
  VRAMHandler("setImage",0,0,VRAMImg)
end)

--==GPUKit Exports==--
VRamKit.BindVRAM = BindVRAM
VRamKit.UnbindVRAM = UnbindVRAM

--==DevKit Exports==--
DevKit.VRAMHandler = VRAMHandler