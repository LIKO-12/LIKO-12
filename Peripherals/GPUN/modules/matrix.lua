--GPU: Screenshot and Label image.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

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
      love.graphics.translate(a or 0,b or 0)
    elseif mode == "scale" then
      love.graphics.scale(a or 1, b or 1)
    elseif mode == "rotate" then
      love.graphics.rotate(a or 0)
    elseif mode == "shear" then
      love.graphics.shear(a or 0, b or 0)
    else
      return error("Unknown mode: "..mode)
    end
  else
    GPU.pushColor()
    love.graphics.origin()
    GPU.popColor()
  end
end

local MatrixStack = 0

function GPU.clearMatrixStack()
  for _=1, MatrixStack do
    love.graphics.pop()
  end
  
  MatrixStack = 0
end

function GPU.pushMatrix()
  if MatrixStack == 256 then
    return error("Maximum stack depth reached, More pushes than pops ?")
  end
  MatrixStack = MatrixStack + 1
  local ok, err = pcall(love.graphics.push)
  if not ok then return error(err) end
end

function GPU.popMatrix()
  if MatrixStack == 0 then
    return error("The stack is empty, More pops than pushes ?")
  end
  MatrixStack = MatrixStack - 1
  local ok, err = pcall(love.graphics.pop)
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
    
    IMG = love.graphics.newImage(IMG)
    
    local QUAD = img:quad(0,0,_LIKO_W,_LIKO_H)
    
    MatrixKit.PatternFill = function()
      love.graphics.setShader(RenderKit.StencilShader)
      
      love.graphics.draw(IMG, QUAD, 0,0)
      
      love.graphics.setShader(RenderKit.DrawShader)
    end
    
    love.graphics.stencil(MatrixKit.PatternFill, "replace", 1)
    love.graphics.setStencilTest("greater",0)
  else
    MatrixKit.PatternFill = nil
    love.graphics.setStencilTest()
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
    love.graphics.setScissor(unpack(MatrixKit.Clip))
  else
    local oldClip = MatrixKit.Clip
    MatrixKit.Clip = false
    love.graphics.setScissor()
    
    return oldClip
  end
  return true
end