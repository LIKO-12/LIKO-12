--GPU: ImageData Object.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local lg = love.graphics

local SharedVars = GPUVars.Shared
local PaletteVars = GPUVars.Palette
local ImageDataVars = GPUVars.ImageData

--==Varss Constants==--
local _ImageTransparent = PaletteVars.ImageTransparent
local _ColorSet = PaletteVars.ColorSet
local _GetColorID = PaletteVars.GetColorID
local colorTo1 = SharedVars.colorTo1
local colorTo255 = SharedVars.colorTo255

--==Localized Lua Library==--
local mathFloor = math.floor
local strFormat = string.format

--==Vars Variables==--
ImageDataVars.PasteImage = false --A walkthrough to avoide exporting the image to png and reloading it.

--==Helper Functions==--

--Convert from LIKO12 palette to real colors.
local function _ExportImage(_,_, r)
  r = mathFloor(r*255)
  if _ImageTransparent[r+1] == 0 then return 0,0,0,0 end
  return colorTo1(_ColorSet[r])
end

--Convert from LIKO-12 palette to real colors ignoring transparent colors.
local function _ExportImageOpaque(_,_, r)
  return colorTo1(_ColorSet[mathFloor(r*255)])
end

--Convert from real colors to LIKO-12 palette
local function _ImportImage(_,_, r,g,b,a)
  return _GetColorID(colorTo255(r,g,b,a))/255,0,0,1
end

--==GPU Imagedata API==--

function GPU.imagedata(w,h)
  local imageData
  if h and tonumber(w) then
    imageData = love.image.newImageData(w,h)
    imageData:mapPixel(function() return 0,0,0,1 end)
  elseif type(w) == "string" then --Load specialized liko12 image format
    if w:sub(0,12) == "LK12;GPUIMG;" then
      w = w:gsub("\n","")
      --luacheck: push ignore 422
      local w,h,data = string.match(w,"LK12;GPUIMG;(%d+)x(%d+);(.+)")
      --luacheck: pop
      imageData = love.image.newImageData(w,h)
      local nextColor = string.gmatch(data,"%x")
      imageData:mapPixel(function()
        return tonumber(nextColor() or "0",16)/255,0,0,1
      end)
    else
      local ok1, fdata = pcall(love.filesystem.newFileData,w,"image.png")
      if not ok1 then return error("Invalid image data") end
      local ok2, img = pcall(love.image.newImageData,fdata)
      if not ok2 then return error("Invalid image data") end
      local ok3, err = pcall(img.mapPixel,img,_ImportImage)
      if not ok3 then print("Invalid image data",err) return error("Invalid image data") end
      imageData = img
    end
  elseif type(w) == "userdata" and w.typeOf and w:typeOf("ImageData") then
    imageData = w
  else
    return error("Invalid arguments")
  end
  
  local id = {}
  
  function id:size() return imageData:getDimensions() end
  function id:getPixel(x,y)
    if not x then return error("Must provide X") end
    if not y then return error("Must provide Y") end
    x,y = mathFloor(x), mathFloor(y)
    if x < 0 or x > self:width()-1 or y < 0 or y > self:height()-1 then
      return false, "Pixel position out from the image region"
    end
    local r = imageData:getPixel(x,y)
    return mathFloor(r*255)
  end
  function id:setPixel(x,y,c)
    if type(c) ~= "number" then return error("Color must be a number, provided "..type(c)) end
    if not x then return error("Must provide X") end
    if not y then return error("Must provide Y") end
    x,y = mathFloor(x), mathFloor(y)
    if x < 0 or x > self:width()-1 or y < 0 or y > self:height()-1 then
      return false, "Pixel position out from the image region"
    end
    c = mathFloor(c) if c < 0 or c > 15 then return error("Color out of range ("..c..") expected [0,15]") end
    imageData:setPixel(x,y,c/255,0,0,1)
    return self
  end
  function id:map(mf)
    imageData:mapPixel(
    function(x,y,r,g,b,a)
      local c = mf(x,y,mathFloor(r*255))
      if c and type(c) ~= "number" then return error("Color must be a number, provided "..type(c)) elseif c then c = mathFloor(c) end
      if c and (c < 0 or c > 15) then return error("Color out of range ("..c..") expected [0,15]") end
      if c then return c/255,0,0,1 else return r,g,b,a end
    end)
    return self
  end
  function id:height() return imageData:getHeight() end
  function id:width() return imageData:getWidth() end
  function id:___pushimgdata() ImageDataVars.PasteImage = imageData end --An internal function used when pasting images.
  
  function id:paste(imgData,dx,dy,sx,sy,sw,sh)
    if type(imgData) ~= "table" then return error("ImageData must be a table, got '"..type(imageData).."'") end
    if not (imgData.typeOf and imgData.typeOf("GPU.imageData")) then return error("Invalid ImageData Object") end
    ImageDataVars.PasteImage = false; imgData:___pushimgdata(); if not ImageDataVars.PasteImage then return error("Fake ImageData Object") end
    imageData:paste(ImageDataVars.PasteImage,dx or 0,dy or 0,sx or 0,sy or 0,sw or ImageDataVars.PasteImage:getWidth(), sh or ImageDataVars.PasteImage:getHeight())
    return self
  end
  
  function id:quad(x,y,qw,qh) return lg.newQuad(x,y,qw or self:width(),qh or self:height(),self:width(),self:height()) end
  function id:image() return GPU.image(imageData) end
  
  function id:export()
    local expData = love.image.newImageData(self:width(),self:height())
    expData:mapPixel(function(x,y) return _ExportImage(x,y, imageData:getPixel(x,y)) end)
    return expData:encode("png"):getString()
  end
  
  function id:exportOpaque()
    local expData = love.image.newImageData(self:width(),self:height())
    expData:mapPixel(function(x,y) return _ExportImageOpaque(x,y, imageData:getPixel(x,y)) end)
    return expData:encode("png"):getString()
  end
  
  function id:enlarge(scale)
    scale = mathFloor(scale or 1)
    if scale <= 0 then scale = 1 end --Protection
    if scale == 1 then return self end
    local newData = GPU.imagedata(self:width()*scale,self:height()*scale)
    self:map(function(x,y,c)
      for iy=0, scale-1 do for ix=0, scale-1 do
        newData:setPixel(x*scale + ix,y*scale + iy,c)
      end end
    end)
    return newData
  end
  
  function id:encode() --Export to liko12 format
    local data = {strFormat("LK12;GPUIMG;%dx%d;",self:width(),self:height())}
    local datalen = 2
    self:map(function(x,_,c)
      if x == 0 then
        data[datalen] = "\n"
        datalen = datalen + 1
      end
      data[datalen] = strFormat("%X",c)
      datalen = datalen + 1
    end)
    return table.concat(data)
  end
  
  function id.type() return "GPU.imageData" end
  function id.typeOf(t) if t == "GPU" or t == "imageData" or t == "GPU.imageData" or t == "LK12" then return true end end
  
  return id
end