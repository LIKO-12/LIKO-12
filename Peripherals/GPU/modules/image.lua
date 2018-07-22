--GPU: Image Object.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local SharedVars = GPUVars.Shared
local RenderVars = GPUVars.Render
local CalibrationVars = GPUVars.Calibration
local VRamVars = GPUVars.VRam

--==Varss Constants==--
local Verify = SharedVars.Verify
local ofs = CalibrationVars.Offsets
local UnbindVRAM = VRamVars.UnbindVRAM

--==GPU Image API==--

function GPU.quad(x,y,w,h,sw,sh)
  local ok, err = pcall(love.graphics.newQuad,x,y,w,h,sw,sh)
  if ok then
    return err
  else
    return error(err)
  end
end

function GPU.image(data)
  local Image, SourceData
  if type(data) == "string" then --Load liko12 specialized image format
    local ok, imageData = pcall(GPU.imagedata,data)
    if not ok then return error(imageData) end
    return imageData:image()
  elseif type(data) == "userdata" and data.typeOf and data:typeOf("ImageData") then
    local ok, err = pcall(love.graphics.newImage,data)
    if not ok then return error("Invalid image data") end
    Image = err
    Image:setWrap("repeat")
    SourceData = data
  end
  
  local i = {}
  
  function i:draw(x,y,r,sx,sy,quad) UnbindVRAM()
    x, y, r, sx, sy = x or 0, y or 0, r or 0, sx or 1, sy or 1
    GPU.pushColor()
    love.graphics.setShader(RenderVars.ImageShader)
    love.graphics.setColor(1,1,1,1)
    if quad then
      love.graphics.draw(Image,quad,math.floor(x+ofs.quad[1]),math.floor(y+ofs.quad[2]),r,sx,sy)
    else
      love.graphics.draw(Image,math.floor(x+ofs.image[1]),math.floor(y+ofs.image[2]),r,sx,sy)
    end
    love.graphics.setShader(RenderVars.DrawShader)
    GPU.popColor()
    RenderVars.ShouldDraw = true
    return self
  end
  
  function i:refresh()
    Image:replacePixels(SourceData)
    return self
  end
  
  function i:size() return Image:getDimensions() end
  function i:width() return Image:getWidth() end
  function i:height() return Image:getHeight() end
  function i:data() return GPU.imagedata(SourceData) end
  function i:quad(x,y,w,h) return love.graphics.newQuad(x,y,w or self:width(),h or self:height(),self:width(),self:height()) end
  function i:batch(bufferSize, usage)
    bufferSize, usage = bufferSize or 1000, usage or "static"
    
    Verify(bufferSize,"bufferSize","number")
    if not (bufferSize >= 1) then return error("Buffersize should be 1 or bigger, provided: "..bufferSize) end
    
    Verify(usage,"usage","string")
    if usage ~= "dynamic" and usage ~= "static" and usage ~= "stream" then
      return error("Invalid usage: "..usage)
    end
    
    local spritebatch = love.graphics.newSpriteBatch(Image,bufferSize, usage)
    
    local sb = {}
    
    function sb:usage() return usage end
    function sb:clear() spritebatch:clear() return self end
    function sb:flush() spritebatch:flush() return self end
    function sb:setBufferSize(size)
      Verify(size,"bufferSize","number")
      if not (size >= 1) then return error("Buffersize should be 1 or bigger, provided: "..size) end
      spritebatch:setBufferSize(size)
      return self
    end
    function sb:getBufferSize() return spritebatch:getBufferSize() end
    function sb:getCount() return spritebatch:getCount() end
    function sb:add(quad,x,y,r,sx,sy,ox,oy,kx,ky)
      x,y,r,sx,sy,ox,oy,kx,ky = x or 0, y or 0, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0
      if type(quad) ~= "userdata" then return error("Quad should be provided, ("..type(quad)..") is not accepted.") end
      Verify(x,"x","number") Verify(y,"y","number")
      Verify(r,"r","number")
      Verify(sx,"sx","number") Verify(sy,"sy","number")
      Verify(ox,"ox","number") Verify(ox,"ox","number")
      Verify(kx,"kx","number") Verify(kx,"kx","number")
      return spritebatch:add(quad,x,y,r,sx,sy,ox,oy,kx,ky)
    end
    function sb:set(id,quad,x,y,r,sx,sy,ox,oy,kx,ky)
      x,y,r,sx,sy,ox,oy,kx,ky = x or 0, y or 0, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0
      if type(quad) ~= "userdata" then return error("Quad should be provided, ("..type(quad)..") is not accepted.") end
      Verify(id,"id","number")
      Verify(x,"x","number") Verify(y,"y","number")
      Verify(r,"r","number")
      Verify(sx,"sx","number") Verify(sy,"sy","number")
      Verify(ox,"ox","number") Verify(ox,"ox","number")
      Verify(kx,"kx","number") Verify(kx,"kx","number")
      local ok, err = pcall(spritebatch.set,spritebatch,id,quad,x,y,r,sx,sy,ox,oy,kx,ky)
      if not ok then return error(err) end
      return self
    end
    function sb:draw(x,y,r,sx,sy,quad) UnbindVRAM()
      x, y, r, sx, sy = x or 0, y or 0, r or 0, sx or 1, sy or 1
      GPU.pushColor()
      love.graphics.setShader(RenderVars.ImageShader)
      love.graphics.setColor(1,1,1,1)
      if quad then
        love.graphics.draw(spritebatch,quad,math.floor(x+ofs.quad[1]),math.floor(y+ofs.quad[2]),r,sx,sy)
      else
        love.graphics.draw(spritebatch,math.floor(x+ofs.image[1]),math.floor(y+ofs.image[2]),r,sx,sy)
      end
      love.graphics.setShader(RenderVars.DrawShader)
      GPU.popColor()
      RenderVars.ShouldDraw = true
      return self
    end
    
    return sb
  end
  
  function i:type() return "GPU.image" end
  function i:typeOf(t) if t == "GPU" or t == "image" or t == "GPU.image" or t == "LK12" then return true end end
  
  return i
end