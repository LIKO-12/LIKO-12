local perpath = ... --The path to the GPU folder.
--/Peripherals/GPU/

--[[
#GPUVARS

ConstantValue, **DynamicValue**

#Shared:
- setColor, getColor, colorTo1, colorTo255
- Verify

#Window:
- LIKO_W, LIKO_H, **LIKO_X**, **LIKO_Y**, **LIKO_Scale**, **Width**, **Height**
- HostToLiko, LikoToHost

#Calibration:
- Offsets

#ImageData:
- weakImageData

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
  --GPUVars: Shared data between the GPU files.
  --DevKit: Shared data between the peripherals.
  local GPU, yGPU, GPUVars, DevKit = {}, {}, {}, {}
  
  GPUVars.Path = perpath
  
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
  
  --==GPUVarss tables creation==--
  --TODO: Sort alphabatically.
  GPUVars.Calibration = {}
  GPUVars.Render = {}
  GPUVars.Window = {}
  GPUVars.Palette = {}
  GPUVars.Shared = {}
  GPUVars.Gif = {}
  GPUVars.VRam = {}
  GPUVars.Misc = {}
  GPUVars.Cursor = {}
  GPUVars.PShaders = {}
  GPUVars.Matrix = {}
  GPUVars.ImageData = {}

  --==Modules Loading==--
  
  local function loadModule(name)
    love.filesystem.load(perpath.."modules/"..name..".lua")(config, GPU, yGPU, GPUVars, DevKit)
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
  loadModule("font")
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