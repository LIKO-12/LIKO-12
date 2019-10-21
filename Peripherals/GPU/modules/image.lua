--GPU: Image Object.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local SharedVars = GPUVars.Shared
local RenderVars = GPUVars.Render
local CalibrationVars = GPUVars.Calibration
local VRamVars = GPUVars.VRam

--==Vars Constants==--
local Verify = SharedVars.Verify
local ofs = CalibrationVars.Offsets
local UnbindVRAM = VRamVars.UnbindVRAM

--==Variables==--
local weakMetatable = { __mode = "k" } --Weak keys
local weakImage = setmetatable({}, weakMetatable)
local weakSourceData = setmetatable({}, weakMetatable)
local weakSpriteBatch = setmetatable({}, weakMetatable)

--==GPU Image API==--

--Shared values between spritebatch objects
local sharedSpriteBatchObject = {}
local spriteBatchMetatable = { __index = sharedSpriteBatchObject, __metatable = false }
do
  function sharedSpriteBatchObject:usage() return usage end
  function sharedSpriteBatchObject:clear()
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
    spritebatch:clear() return self end
  function sharedSpriteBatchObject:flush()
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
    spritebatch:flush() return self end
  function sharedSpriteBatchObject:setBufferSize(size)
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
    Verify(size,"bufferSize","number")
    if not (size >= 1) then return error("Buffersize should be 1 or bigger, provided: "..size) end
    spritebatch:setBufferSize(size)
    return self
  end
  function sharedSpriteBatchObject:getBufferSize()
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
    return spritebatch:getBufferSize() end
  function sharedSpriteBatchObject:getCount()
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
    return spritebatch:getCount() end
  function sharedSpriteBatchObject:add(quad,x,y,r,sx,sy,ox,oy,kx,ky)
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
    x,y,r,sx,sy,ox,oy,kx,ky = x or 0, y or 0, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0
    if type(quad) ~= "userdata" then return error("Quad should be provided, ("..type(quad)..") is not accepted.") end
    Verify(x,"x","number") Verify(y,"y","number")
    Verify(r,"r","number")
    Verify(sx,"sx","number") Verify(sy,"sy","number")
    Verify(ox,"ox","number") Verify(ox,"ox","number")
    Verify(kx,"kx","number") Verify(kx,"kx","number")
    return spritebatch:add(quad,x,y,r,sx,sy,ox,oy,kx,ky)
  end
  function sharedSpriteBatchObject:set(id,quad,x,y,r,sx,sy,ox,oy,kx,ky)
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
    x,y,r,sx,sy,ox,oy,kx,ky = x or 0, y or 0, r or 0, sx or 1, sy or sx or 1, ox or 0, oy or 0, kx or 0, ky or 0
    if type(quad) ~= "userdata" then return error("Quad should be provided, ("..type(quad)..") is not accepted.") end
    Verify(id,"id","number")
    Verify(x,"x","number") Verify(y,"y","number")
    Verify(r,"r","number")
    Verify(sx,"sx","number") Verify(sy,"sy","number")
    Verify(ox,"ox","number") Verify(oy,"oy","number")
    Verify(kx,"kx","number") Verify(ky,"ky","number")
    local ok, err = pcall(spritebatch.set,spritebatch,id,quad,x,y,r,sx,sy,ox,oy,kx,ky)
    if not ok then return error(err) end
    return self
  end
  function sharedSpriteBatchObject:draw(x,y,r,sx,sy,quad) UnbindVRAM()
    local spritebatch = weakSpriteBatch[self]; if not spritebatch then return error("Use : instead of . when calling spritebatch object methods!") end
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

  function sharedSpriteBatchObject:type() return "GPU.spriteBatch" end
  function sharedSpriteBatchObject:typeOf(t) if t == "GPU" or t == "spriteBatch" or t == "GPU.spritebatch" or t == "LK12" then return true end end
end

--Shared values between image objects
local sharedImageObject = {}
local imageMetatable = { __index = sharedImageObject, __metatable = {} }
do
  function sharedImageObject:draw(x,y,r,sx,sy,quad) UnbindVRAM()
    local Image = weakImage[self]; if not Image then return error("Use : instead of . when calling image object methods!") end

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

  function sharedImageObject:refresh()
    local Image = weakImage[self]; if not Image then return error("Use : instead of . when calling image object methods!") end
    Image:replacePixels(weakSourceData[self])
    return self
  end

  function sharedImageObject:size()
    local Image = weakImage[self]; if not Image then return error("Use : instead of . when calling image object methods!") end
    return Image:getDimensions() end
  function sharedImageObject:width()
    local Image = weakImage[self]; if not Image then return error("Use : instead of . when calling image object methods!") end
    return Image:getWidth() end
  function sharedImageObject:height()
    local Image = weakImage[self]; if not Image then return error("Use : instead of . when calling image object methods!") end
    return Image:getHeight() end
  function sharedImageObject:data() 
    local SourceData = weakSourceData[self]; if not SourceData then return error("Use : instead of . when calling image object methods!") end
    return GPU.imagedata(SourceData) end
  function sharedImageObject:quad(x,y,w,h)
    local SourceData = weakSourceData[self]; if not SourceData then return error("Use : instead of . when calling image object methods!") end
    return love.graphics.newQuad(x,y,w or self:width(),h or self:height(),self:width(),self:height()) end
  
  function sharedImageObject:batch(bufferSize, usage)
    local Image = weakImage[self]; if not Image then return error("Use : instead of . when calling image object methods!") end
    bufferSize, usage = bufferSize or 1000, usage or "static"
    
    Verify(bufferSize,"bufferSize","number")
    if not (bufferSize >= 1) then return error("Buffersize should be 1 or bigger, provided: "..bufferSize) end
    
    Verify(usage,"usage","string")
    if usage ~= "dynamic" and usage ~= "static" and usage ~= "stream" then
      return error("Invalid usage: "..usage)
    end
    
    local spritebatch = love.graphics.newSpriteBatch(Image, bufferSize, usage)
    local sb = setmetatable({}, spriteBatchMetatable)
    weakSpriteBatch[sb] = spritebatch --It's a weak secret
    
    return sb
  end
  
  function sharedImageObject:type() return "GPU.image" end
  function sharedImageObject:typeOf(t) if t == "GPU" or t == "image" or t == "GPU.image" or t == "LK12" then return true end end
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
  
  local i = setmetatable({}, imageMetatable)
  weakImage[i], weakSourceData[i] = Image, SourceData

  return i
end

function GPU.quad(x,y,w,h,sw,sh)
  local ok, err = pcall(love.graphics.newQuad,x,y,w,h,sw,sh)
  if ok then
    return err
  else
    return error(err)
  end
end