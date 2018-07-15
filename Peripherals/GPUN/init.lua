local perpath = select(1,...) --The path to the GPU folder.
--/Peripherals/GPUN/

--[[
#GPUKITS

ConstantValue, **DynamicValue**

#Window:
- LIKO_W, LIKO_H, **LIKO_X**, **LIKO_Y**, **LIKO_Scale**, **Width**, **Height**
- HostToLiko, LikoToHost

#Calibration:
- Offsets

#Palette:
- ColorSet, DrawPalette, ImagePalette, ImageTransparent, DisplayPalette

#Shared:
- setColor, getColor, colorTo1, colorTo255
- GetColor, GetColorID
- EncodeTransparent, ExportImage, ExportImageOpaque
- Verify

#Render:
- **Flipped**, **ShouldDraw**, **DevKitDraw**, **AlwaysDraw**, **AlwaysDrawTimer**
- DrawShader, ImageShader, DisplayShader, StencilShader

#Gif:
- **PChanged**

]]

return function(config) --A function that creates a new GPU peripheral.
  
  --GPU: the non-yielding APIS of the GPU.
  --yGPU: the yield APIS of the GPU.
  --GPUKit: Shared data between the GPU files.
  --DevKit: Shared data between the peripherals.
  local GPU, yGPU, GPUKit, DevKit = {}, {}, {}, {}
  
  GPUKit.Path = perpath
  
  --==Basic initialization==--
  
  --Create appdata directories:
  if not love.filesystem.getInfo("Shaders","directory") then
    love.filesystem.createDirectory("Shaders")
  end
  
  if not love.filesystem.getInfo("Screenshots","directory") then
    love.filesystem.createDirectory("Screenshots")
  end
  
  if not love.filesystem.getInfo("GIF Recordings","directory") then
    love.filesystem.createDirectory("GIF Recordings")
  end
  
  --Set the scaling filter to the nearest pixel.
  love.graphics.setDefaultFilter("nearest","nearest")
  
  --==GPUKits tables creation==--
  --TODO: Sort alphabatically.
  GPUKit.Calibration = {}
  GPUKit.Render = {}
  GPUKit.Window = {}
  GPUKit.Palette = {}
  GPUKit.Shared = {}
  GPUKit.Gif = {}
  
  --==Modules Loading==--
  
  local function loadModule(name)
    love.filesystem.load(perpath.."modules/"..name..".lua")(config, GPU, yGPU, GPUKit, DevKit)
  end
  
  loadModule("window")
  loadModule("calibration")
  loadModule("palette")
  loadModule("shared")
  loadModule("render")
  
end