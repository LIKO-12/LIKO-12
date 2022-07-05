--GPU: Mouse Cursor.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local lg = love.graphics

local events = require("Engine.events")

local PaletteVars = GPUVars.Palette
local RenderVars = GPUVars.Render
local SharedVars = GPUVars.Shared
local WindowVars = GPUVars.Window
local CursorVars = GPUVars.Cursor

--==Varss Constants==--
local _ImageTransparent = PaletteVars.ImageTransparent
local PaletteStack = PaletteVars.PaletteStack
local Verify = SharedVars.Verify

--==Local Functions==--

--Apply transparent colors effect on LIKO12 Images when encoded to PNG
local function _EncodeTransparent(_,_, r,g,b,a)
  if _ImageTransparent[math.floor(r*255)+1] == 0 then return 0,0,0,0 end
  return r,g,b,a
end

--==Vars Variables==--

CursorVars.GrappedCursor = false --If the cursor must be drawed by the GPU (not using a system cursor)
CursorVars.Cursor = "none"

--==Local Variables==--

local _CursorsCache = {}

--==GPU Cursor API==--
function GPU.cursor(imgdata,name,hx,hy)
  if type(imgdata) == "string" then --Set the current cursor
    if CursorVars.GrappedCursor then if not name then RenderVars.AlwaysDraw = false; RenderVars.ShouldDraw = true end elseif name then RenderVars.AlwaysDraw = true end
    if CursorVars.Cursor == imgdata and not ((CursorVars.GrappedCursor and not name) or (name and not CursorVars.GrappedCursor)) then return end
    CursorVars.GrappedCursor = name
    if (not _CursorsCache[imgdata]) and (imgdata ~= "none") then return error("Cursor doesn't exist: "..imgdata) end
    CursorVars.Cursor = imgdata
    if CursorVars.Cursor == "none" or CursorVars.GrappedCursor then
      love.mouse.setVisible(false)
    elseif love.mouse.isCursorSupported() then
      love.mouse.setVisible(true)
      love.mouse.setCursor(_CursorsCache[CursorVars.Cursor].cursor)
    end
  elseif type(imgdata) == "table" then --Create a new cursor from an image.
    if not( imgdata.enlarge and imgdata.export and imgdata.type ) then return error("Invalied image") end
    if imgdata:type() ~= "GPU.imageData" then return error("Invalied image object") end

    name = name or "default"
    Verify(name,"Name","string")

    hx, hy = hx or 0, hy or 0
    hx = Verify(hx,"Hot X","number",true)
    hy = Verify(hy,"Hot Y","number",true)

    local enimg = imgdata:enlarge(WindowVars.LIKOScale)
    --local img = lg.newImage(love.filesystem.newFileData(imgdata:export(),"cursor.png"))
    local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
    local gifimg = love.image.newImageData(imgdata:size())
    gifimg:mapPixel(function(x,y) return imgdata:getPixel(x,y)/255,0,0,1 end)
    gifimg:mapPixel(_EncodeTransparent)
    gifimg = lg.newImage(gifimg)

    local hotx, hoty = hx*math.floor(WindowVars.LIKOScale), hy*math.floor(WindowVars.LIKOScale) --Converted to host scale
    local cur = love.mouse.isCursorSupported() and love.mouse.newCursor(limg,hotx,hoty) or {}
    local palt = {}
    for i=1, 16 do
      table.insert(palt,_ImageTransparent[i])
    end
    _CursorsCache[name] = {cursor=cur,imgdata=imgdata,gifimg=gifimg,hx=hx,hy=hy,palt=palt}
  elseif type(imgdata) == "nil" then
    if CursorVars.Cursor == "none" then
      return CursorVars.Cursor
    else
      return CursorVars.Cursor, _CursorsCache[CursorVars.Cursor].imgdata, _CursorsCache[CursorVars.Cursor].hx+1, _CursorsCache[CursorVars.Cursor].hy+1
    end
  else --Invalied
    return error("The first argument must be a string, image or nil")
  end
end

local function rebuildCursors() --The new size will be calculated in the top, because events are called by the order they were registered with
  if not love.mouse.isCursorSupported() then return end
  for k, cursor in pairs(_CursorsCache) do
    --Hack
    GPU.pushPalette()
    GPU.pushPalette()
    for i=1, 16 do
      PaletteStack[#PaletteStack].trans[i] = cursor.palt[i]
    end
    GPU.popPalette()

    local enimg = cursor.imgdata:enlarge(WindowVars.LIKOScale)
    local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
    local hotx, hoty = cursor.hx*math.floor(WindowVars.LIKOScale), cursor.hy*math.floor(WindowVars.LIKOScale) --Converted to host scale
    local cur = love.mouse.newCursor(limg,hotx,hoty)
    _CursorsCache[k].cursor = cur
    GPU.popPalette()
  end
  local cursor = CursorVars.Cursor; CursorVars.Cursor = "none" --Force the cursor to update.
  GPU.cursor(cursor,CursorVars.GrappedCursor)
end

events.register("love:resize",rebuildCursors)

--==GPUVars Exports==--
CursorVars.CursorsCache = _CursorsCache
CursorVars.rebuildCursors = rebuildCursors