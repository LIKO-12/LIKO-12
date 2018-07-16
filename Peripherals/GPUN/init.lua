local perpath = select(1,...) --The path to the GPU folder.
--/Peripherals/GPUN/

--[[
#GPUKITS

ConstantValue, **DynamicValue**

#Shared:
- setColor, getColor, colorTo1, colorTo255
- Verify

#Window:
- LIKO_W, LIKO_H, **LIKO_X**, **LIKO_Y**, **LIKO_Scale**, **Width**, **Height**
- HostToLiko, LikoToHost

#Calibration:
- Offsets

#VRam:
- BindVRAM, UnbindVRAM

#Palette:
- ColorSet, DrawPalette, ImagePalette, ImageTransparent, DisplayPalette
- GetColor, GetColorID
- PaletteStack

#Misc:
- **LastMSG**, **LastMSGTColor**, **LastMSGColor**, **LastMSGGif**, **MSGTimer**, systemMessage

#Matrix:
- **Clip**, **PatternFill**

#PShaders:
- **ActiveShader**, **_PostShaderTimer**

#ImageData:
- PasteImage

#Cursor:
- **GrappedCursor**, **Cursor**, CursorsCache

#Gif:
- **PChanged**

#Render:
- **Flipped**, **ShouldDraw**, **DevKitDraw**, **AlwaysDraw**, **AlwaysDrawTimer**
- DrawShader, ImageShader, DisplayShader, StencilShader
- ScreenCanvas

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
  love.graphics.setLineStyle("rough") --Set the line style.
  
  --Some graphics settings.
  love.graphics.setLineJoin("miter") --Set the line join style.
  love.graphics.setPointSize(1) --Set the point size to 1px.
  love.graphics.setLineWidth(1) --Set the line width to 1px.
  
  --==GPUKits tables creation==--
  --TODO: Sort alphabatically.
  GPUKit.Calibration = {}
  GPUKit.Render = {}
  GPUKit.Window = {}
  GPUKit.Palette = {}
  GPUKit.Shared = {}
  GPUKit.Gif = {}
  GPUKit.ImageData = {}
  GPUKit.VRam = {}
  GPUKit.Misc = {}
  GPUKit.Cursor = {}
  GPUKit.PShaders = {}
  GPUKit.Matrix = {}
  
  --==Modules Loading==--
  
  local function loadModule(name)
    love.filesystem.load(perpath.."modules/"..name..".lua")(config, GPU, yGPU, GPUKit, DevKit)
  end
  
  loadModule("shared")
  loadModule("window")
  loadModule("mouse")
  loadModule("calibration")
  loadModule("vram")
  loadModule("palette")
  loadModule("miscellaneous")
  loadModule("matrix")
  loadModule("postShaders")
  loadModule("print")
  loadModule("shapes")
  loadModule("image")
  loadModule("imagedata")
  loadModule("screenshot")
  loadModule("cursor")
  loadModule("gif")
  loadModule("render")
  
  return GPU, yGPU, DevKit
  
end