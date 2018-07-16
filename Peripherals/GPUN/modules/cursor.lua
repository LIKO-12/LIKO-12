--GPU: Mouse Cursor.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local events = require("Engine.events")

local PaletteKit = GPUKit.Palette
local RenderKit = GPUKit.Render
local SharedKit = GPUKit.Shared
local WindowKit = GPUKit.Window
local CursorKit = GPUKit.Cursor

--==Kits Constants==--
local _ImageTransparent = PaletteKit.ImageTransparent
local PaletteStack = PaletteKit.PaletteStack
local Verify = SharedKit.Verify

--==Local Functions==--

--Apply transparent colors effect on LIKO12 Images when encoded to PNG
local function _EncodeTransparent(_,_, r,g,b,a)
  if _ImageTransparent[math.floor(r*255)+1] == 0 then return 0,0,0,0 end
  return r,g,b,a
end

--==Kit Variables==--

CursorKit.GrappedCursor = false --If the cursor must be drawed by the GPU (not using a system cursor)
CursorKit.Cursor = "none"

--==Local Variables==--

local _CursorsCache = {}

--==GPU Cursor API==--
function GPU.cursor(imgdata,name,hx,hy)
  if type(imgdata) == "string" then --Set the current cursor
    if CursorKit.GrappedCursor then if not name then RenderKit.AlwaysDraw = false; RenderKit.ShouldDraw = true end elseif name then RenderKit.AlwaysDraw = true end
    if CursorKit.Cursor == imgdata and not ((CursorKit.GrappedCursor and not name) or (name and not CursorKit.GrappedCursor)) then return end
    CursorKit.GrappedCursor = name
    if (not _CursorsCache[imgdata]) and (imgdata ~= "none") then return error("Cursor doesn't exists: "..imgdata) end
    CursorKit.Cursor = imgdata
    if CursorKit.Cursor == "none" or CursorKit.GrappedCursor then
      love.mouse.setVisible(false)
    elseif love.mouse.isCursorSupported() then
      love.mouse.setVisible(true)
      love.mouse.setCursor(_CursorsCache[CursorKit.Cursor].cursor)
    end
  elseif type(imgdata) == "table" then --Create a new cursor from an image.
    if not( imgdata.enlarge and imgdata.export and imgdata.type ) then return error("Invalied image") end
    if imgdata:type() ~= "GPU.imageData" then return error("Invalied image object") end
    
    name = name or "default"
    Verify(name,"Name","string")
    
    hx, hy = hx or 0, hy or 0
    hx = Verify(hx,"Hot X","number",true)
    hy = Verify(hy,"Hot Y","number",true)
    
    local enimg = imgdata:enlarge(WindowKit.LIKOScale)
    --local img = love.graphics.newImage(love.filesystem.newFileData(imgdata:export(),"cursor.png"))
    local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
    local gifimg = love.image.newImageData(imgdata:size())
    gifimg:mapPixel(function(x,y) return imgdata:getPixel(x,y)/255,0,0,1 end)
    gifimg:mapPixel(_EncodeTransparent)
    gifimg = love.graphics.newImage(gifimg)
    
    local hotx, hoty = hx*math.floor(WindowKit.LIKOScale), hy*math.floor(WindowKit.LIKOScale) --Converted to host scale
    local cur = love.mouse.isCursorSupported() and love.mouse.newCursor(limg,hotx,hoty) or {}
    local palt = {}
    for i=1, 16 do
      table.insert(palt,_ImageTransparent[i])
    end
    _CursorsCache[name] = {cursor=cur,imgdata=imgdata,gifimg=gifimg,hx=hx,hy=hy,palt=palt}
  elseif type(imgdata) == "nil" then
    if CursorKit.Cursor == "none" then
      return CursorKit.Cursor
    else
      return CursorKit.Cursor, _CursorsCache[CursorKit.Cursor].imgdata, _CursorsCache[CursorKit.Cursor].hx+1, _CursorsCache[CursorKit.Cursor].hy+1
    end
  else --Invalied
    return error("The first argument must be a string, image or nil")
  end
end

events.register("love:resize",function() --The new size will be calculated in the top, because events are called by the order they were registered with
  if not love.mouse.isCursorSupported() then return end
  for k, cursor in pairs(_CursorsCache) do
     --Hack
    GPU.pushPalette()
    GPU.pushPalette()
    for i=1, 16 do
      PaletteStack[#PaletteStack].trans[i] = cursor.palt[i]
    end
    GPU.popPalette()
    
    local enimg = cursor.imgdata:enlarge(WindowKit.LIKOScale)
    local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
    local hotx, hoty = cursor.hx*math.floor(WindowKit.LIKOScale), cursor.hy*math.floor(WindowKit.LIKOScale) --Converted to host scale
    local cur = love.mouse.newCursor(limg,hotx,hoty)
    _CursorsCache[k].cursor = cur
    GPU.popPalette()
  end
  local cursor = CursorKit.Cursor; CursorKit.Cursor = "none" --Force the cursor to update.
  GPU.cursor(cursor,CursorKit.GrappedCursor)
end)

--==GPUKit Exports==--
CursorKit.CursorsCache = _CursorsCache