--GPU: Colors palettes.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local PaletteVars = GPUVars.Palette
local CursorVars = GPUVars.Cursor
local SharedVars = GPUVars.Shared
local RenderVars = GPUVars.Render
local GifVars = GPUVars.Gif

--==Varss Constants==--

local Verify = SharedVars.Verify

--==Localized Lua Library==--

local mathFloor = math.floor

--==Local Variables==--

--The colorset (PICO-8 Palette by default)
local _ColorSet = Config._ColorSet or {
  {0,0,0,255}, --Black 1
  {28,43,83,255}, --Dark Blue 2
  {127,36,84,255}, --Dark Red 3
  {0,135,81,255}, --Dark Green 4
  {171,82,54,255}, --Brown 5
  {96,88,79,255}, --Dark Gray 6
  {195,195,198,255}, --Gray 7
  {255,241,233,255}, --White 8
  {237,27,81,255}, --Red 9
  {250,162,27,255}, --Orange 10
  {247,236,47,255}, --Yellow 11
  {93,187,77,255}, --Green 12
  {81,166,220,255}, --Blue 13
  {131,118,156,255}, --Purple 14
  {241,118,166,255}, --Pink 15
  {252,204,171,255} --Human Skin 16
} --The colorset of the gpu

--This is a path of an image containing the palette colors
if type(_ColorSet) == "string" then
  --Load the image
  local paletteImageData = love.image.newImageData(_ColorSet)
  
  --Make the _Colorset a table
  _ColorSet = {}
  
  --Read the colors
  paletteImageData:mapPixel(function(x,y, r,g,b,a)
    if #_ColorSet < 16 then
      _ColorSet[#_ColorSet + 1] = {r*255,g*255,b*255,255}
    end
    return r,g,b,a
  end)
end

local _DefaultColorSet = {} --The default palette for the operating system.

for k,v in ipairs(_ColorSet) do
  _ColorSet[k-1] = v
  _DefaultColorSet[k-1] = v
end
_ColorSet[16] = nil

--==Helper Functions==--

local function _GetColor(c) return _ColorSet[c or 0] or _ColorSet[0] end --Get the (rgba) table of a color id.

local _ColorSetLookup = {}
for k,v in ipairs(_ColorSet) do _ColorSetLookup[table.concat(v)] = k end
local function _GetColorID(...) --Get the color id by the (rgba) table.
  local col = {...}
  if col[4] == 0 then return 0 end
  return _ColorSetLookup[table.concat(col)] or 0
end

--==Shaders Palettes==--

local _DrawPalette = {} --The palette mapping for all drawing opereations except image:draw (p = 1).
local _ImagePalette = {} --The palette mapping for image:draw opereations (p = 2).
local _ImageTransparent = {} --The transparent colors palette, 1 for solid, 0 for transparent.
local _DisplayPalette = {} --The final display shader palette, converts the red pixel values to a palette color.

--Build the default palettes.
for i=1,16 do
  _ImageTransparent[i] = (i==1 and 0 or 1) --Black is transparent by default.
  _DrawPalette[i] = i-1
  _ImagePalette[i] = i-1
  _DisplayPalette[i] = _ColorSet[i-1]
end
_DisplayPalette[17] = {0,0,0,0} --A bug in unpack ???
_DrawPalette[17] = 0
_ImagePalette[17] = 0
_ImageTransparent[17] = 0

--==Palettes API==--
function GPU.colorPalette(id,r,g,b)
  if not (id or r or g or b) then --Reset
    for i=0,15 do
      r,g,b = _DefaultColorSet[i][1], _DefaultColorSet[i][2], _DefaultColorSet[i][3]
      _ColorSet[i] = {r,g,b,255}
      _DisplayPalette[i+1] = _ColorSet[i]
    end
    RenderVars.DisplayShader:send('palette', unpack(_DisplayPalette)) --Upload the new colorset.
    RenderVars.ShouldDraw = true
    GifVars.PChanged = true
    CursorVars.rebuildCursors()
    return
  end
  
  id = Verify(id,"Color ID","number")
  if not _ColorSet[id] then return error("Color ID out of range ("..id..") Must be [0,15]") end
  
  if r or g or b then
    r,g,b = r or _ColorSet[id][1], g or _ColorSet[id][2], b or _ColorSet[id][3]
    r = Verify(r,"Red value","number")
    g = Verify(g,"Green value","number")
    b = Verify(b,"Blue value","number")
    if r < 0 or r > 255 then return error("Red value out of range ("..r..") Must be [0,255]") end
    if g < 0 or g > 255 then return error("Green value out of range ("..g..") Must be [0,255]") end
    if b < 0 or b > 255 then return error("Blue value out of range ("..b..") Must be [0,255]") end
    _ColorSet[id] = {r,g,b,255}
    _DisplayPalette[id+1] = _ColorSet[id]
    RenderVars.DisplayShader:send('palette', unpack(_DisplayPalette)) --Upload the new colorset.
    RenderVars.ShouldDraw = true
    GifVars.PChanged = true
    CursorVars.rebuildCursors()
  else
    return unpack(_ColorSet[id])
  end
end

--Call with color id to set the active color.
--Call with no args to get the current acive color id.
function GPU.color(id)
  if id then
    id = Verify(id,"The color id","number")
    if id > 15 or id < 0 then return error("The color id is out of range ("..id..") Must be [0,15]") end --Error
    love.graphics.setColor(id/255,0,0,1) --Set the active color.
  else
    return mathFloor(love.graphics.getColor()*255) --Return the current color.
  end
end

--Map pallete colors
function GPU.pal(c0,c1,p)
  local drawchange = false  --Has any changes been made to the draw palette (p=1).
  local imagechange = false  --Has any changes been made to the image:draw palette (p=2).
  
  --Error check all the arguments.
  if c0 then c0 = Verify(c0, "C0","number",true) end
  if c1 then c1 = Verify(c1, "C1","number",true) end
  if p then p = Verify(p, "P","number",true) end
  if c0 and (c0 < 0 or c0 > 15) then return error("C0 is out of range ("..c0..") expected [0,15]") end
  if c1 and (c1 < 0 or c1 > 15) then return error("C1 is out of range ("..c1..") expected [0,15]") end
  if p and (p < 0 or p > 1) then return error("P is out of range ("..p..") expected [0,1]") end
  
  --Reset the palettes.
  if (not c0) and (not c1) then
    for i=1, 16 do
      if _DrawPalette[i] ~= i-1 and ((not p) or p == 0) then
        drawchange = true
        _DrawPalette[i] = i-1
      end
      
      if _ImagePalette[i] ~= i-1 and ((not p) or p > 0) then
        imagechange = true
        _ImagePalette[i] = i-1
      end
    end
  --Reset a specific color
  elseif not(c1) then
    if ((not p) or p == 0) and _DrawPalette[c0+1] ~= c0 then
      drawchange = true
      _DrawPalette[c0+1] = c0
    end
    
    if ((not p) or p > 0) and _ImagePalette[c0+1] ~= c0 then
      imagechange = true
      _ImagePalette[c0+1] = c0
    end
  --Modify the palette
  elseif c0 and c1 then
    if ((not p) or p == 0) and _DrawPalette[c0+1] ~= c1 then
      drawchange = true
      _DrawPalette[c0+1] = c1
    end
    
    if ((not p) or p > 0) and _ImagePalette[c0+1] ~= c1 then
      imagechange = true
      _ImagePalette[c0+1] = c1
    end
  end
  --If changes has been made then upload the data to the shaders.
  if drawchange then RenderVars.DrawShader:send('palette',unpack(_DrawPalette)) end
  if imagechange then RenderVars.ImageShader:send('palette',unpack(_ImagePalette)) end
end

function GPU.palt(c,t)
  local changed = false
  if c then
    c = Verify(c,"Color","number")
    if (c < 0 or c > 15) then return error("Color out of range ("..c..") expected [0,15]") end
    
    if _ImageTransparent[c+1] == (t and 1 or 0) then
      _ImageTransparent[c+1] = (t and 0 or 1)
      changed = true
    end
  else
    for i=2,16 do
      if _ImageTransparent[i] == 0 then
        changed = true
        _ImageTransparent[i] = 1
      end
    end
    if _ImageTransparent[1] == 1 then
      changed = true
      _ImageTransparent[1] = 0
    end
  end
  if changed then RenderVars.ImageShader:send('transparent', unpack(_ImageTransparent)) end
end

--==Palettes Stacks==--
local ColorStack = {} --The colors stack (pushColor,popColor)
local PaletteStack = {} --The palette stack (pushPalette,popPalette)

--Push the current active color to the ColorStack.
function GPU.pushColor()
  table.insert(ColorStack,GPU.color()) --Add the active color id to the stack.
end

--Pop the last color from the ColorStack and set it to the active color.
function GPU.popColor()
  if #ColorStack == 0 then return error("No more colors to pop.") end --Error
  GPU.color(ColorStack[#ColorStack]) --Set the last color in the stack to be the active color.
  table.remove(ColorStack,#ColorStack) --Remove the last color in the stack.
end

function GPU.pushPalette()
  local pal = {}
  pal.draw = {}
  pal.img = {}
  pal.trans = {}
  for i=1, 16 do
    table.insert(pal.draw,_DrawPalette[i])
    table.insert(pal.img,_ImagePalette[i])
    table.insert(pal.trans,_ImageTransparent[i])
  end
  table.insert(PaletteStack,pal)
end

function GPU.popPalette()
  if #PaletteStack == 0 then return error("No more palettes to pop.") end --Error
  local pal = PaletteStack[#PaletteStack]
  local drawchange, imgchange, transchange = false,false,false
  for i=1,16 do
    if _DrawPalette[i] ~= pal.draw[i] then
      drawchange = true
      _DrawPalette[i] = pal.draw[i]
    end
    
    if _ImagePalette[i] ~= pal.img[i] then
      imgchange = true
      _ImagePalette[i] = pal.img[i]
    end
    
    if _ImageTransparent[i] ~= pal.trans[i] then
      transchange = true
      _ImageTransparent[i] = pal.trans[i]
    end
  end
  if drawchange then RenderVars.DrawShader:send('palette',unpack(_DrawPalette)) end
  if imgchange then RenderVars.ImageShader:send('palette',unpack(_ImagePalette)) end
  if transchange then RenderVars.ImageShader:send('transparent', unpack(_ImageTransparent)) end
  table.remove(PaletteStack,#PaletteStack)
end

--==GPUVars Exports==--
PaletteVars.ColorSet = _ColorSet
PaletteVars.DrawPalette = _DrawPalette
PaletteVars.ImagePalette = _ImagePalette
PaletteVars.ImageTransparent = _ImageTransparent
PaletteVars.DisplayPalette = _DisplayPalette
PaletteVars.GetColor = _GetColor
PaletteVars.GetColorID= _GetColorID
PaletteVars.PaletteStack = PaletteStack

--==DevKit Exports==--
DevKit._GetColor = _GetColor
DevKit._ColorSet = _ColorSet