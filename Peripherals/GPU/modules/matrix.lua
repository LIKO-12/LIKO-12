--GPU: Screenshot and Label image.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local lg = love.graphics

local SharedKit = GPUKit.Shared
local RenderKit = GPUKit.Render
local WindowKit = GPUKit.Window
local ImageDataKit = GPUKit.ImageData
local MatrixKit = GPUKit.Matrix

--==Kits Constants==--

local Verify = SharedKit.Verify
local _LIKO_W = WindowKit.LIKO_W
local _LIKO_H = WindowKit.LIKO_H

--==Local Variables==--

MatrixKit.Clip = false --The current active clipping region.
MatrixKit.PatternFill = false --The pattern stencil function.

--==GPU Matrix API==--

--Camera Functions
function GPU.cam(mode,a,b)
  if mode then Verify(mode,"Mode","string") end
  if a then Verify(a,"a","number",true) end
  if b then Verify(b,"b","number",true) end
  
  if mode then
    if mode == "translate" then
      lg.translate(a or 0,b or 0)
    elseif mode == "scale" then
      lg.scale(a or 1, b or 1)
    elseif mode == "rotate" then
      lg.rotate(a or 0)
    elseif mode == "shear" then
      lg.shear(a or 0, b or 0)
    else
      return error("Unknown mode: "..mode)
    end
  else
    GPU.pushColor()
    lg.origin()
    GPU.popColor()
  end
end

local MatrixStack = 0

function GPU.clearMatrixStack()
  for _=1, MatrixStack do
    lg.pop()
  end
  
  MatrixStack = 0
end

function GPU.pushMatrix()
  if MatrixStack == 256 then
    return error("Maximum stack depth reached, More pushes than pops ?")
  end
  MatrixStack = MatrixStack + 1
  local ok, err = pcall(lg.push)
  if not ok then return error(err) end
end

function GPU.popMatrix()
  if MatrixStack == 0 then
    return error("The stack is empty, More pops than pushes ?")
  end
  MatrixStack = MatrixStack - 1
  local ok, err = pcall(lg.pop)
  if not ok then return error(err) end
end

function GPU.patternFill(img)
  if img then
    Verify(img,"Pattern ImageData","table")
    if not img.typeOf or not img.typeOf("GPU.imageData") then return error("Invalid ImageData") end
    
    local IMG = love.image.newImageData(img:size())
    img:___pushimgdata()
    IMG:paste(ImageDataKit.PasteImage,0,0)
    ImageDataKit.PasteImage = nil
    
    IMG = lg.newImage(IMG)
    
    local QUAD = img:quad(0,0,_LIKO_W,_LIKO_H)
    
    MatrixKit.PatternFill = function()
      lg.setShader(RenderKit.StencilShader)
      
      lg.draw(IMG, QUAD, 0,0)
      
      lg.setShader(RenderKit.DrawShader)
    end
    
    lg.stencil(MatrixKit.PatternFill, "replace", 1)
    lg.setStencilTest("greater",0)
  else
    MatrixKit.PatternFill = nil
    lg.setStencilTest()
  end
end

function GPU.clip(x,y,w,h)
  if x then
    if type(x) == "table" then
      x,y,w,h = unpack(x)
    end
    
    Verify(x,"X","number")
    Verify(y,"Y","number")
    Verify(w,"W","number")
    Verify(h,"H","number")
    
    MatrixKit.Clip = {x,y,w,h}
    lg.setScissor(unpack(MatrixKit.Clip))
  else
    local oldClip = MatrixKit.Clip
    MatrixKit.Clip = false
    lg.setScissor()
    
    return oldClip
  end
  return true
end