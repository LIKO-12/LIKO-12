--GPU: Colors palettes.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local SharedKit = GPUKit.Shared
local PaletteKit = GPUKit.Palette
local WindowKit = GPUKit.Window

--==Kits Constants==--
local _ColorSet = PaletteKit.ColorSet

--==Localized Lua Library==--
local mathFloor = math.floor

--==Shared Functions==--
--Wrapper for setColor to use 0-255 values
local function setColor(r,g,b,a)
  local r,g,b,a = r,g,b,a
  if type(r) == "table" then
    r,g,b,a = unpack(r)
  end
  if r then r = r/255 end
  if g then g = g/255 end
  if b then b = b/255 end
  if a then a = a/255 end
  
  love.graphics.setColor(r, g, b, a)
end

--Wrapper for getColor to use 0-255 values
local function getColor()
  local r,g,b,a = love.graphics.getColor()
  return mathFloor(r*255), mathFloor(g*255), mathFloor(b*255), mathFloor(a*255)
end

--Convert color from 0-255 to 0-1
local function colorTo1(r,g,b,a)
  local r,g,b,a = r,g,b,a
  if type(r) == "table" then r,g,b,a = unpack(r) end
  if r then r = r/255 end
  if g then g = g/255 end
  if b then b = b/255 end
  if a then a = a/255 end
  return r,g,b,a
end

--Convert color from 0-1 to 0-255
local function colorTo255(r,g,b,a)
  local r,g,b,a = r,g,b,a
  if type(r) == "table" then r,g,b,a = unpack(r) end
  if r then r = mathFloor(r*255) end
  if g then g = mathFloor(g*255) end
  if b then b = mathFloor(b*255) end
  if a then a = mathFloor(a*255) end
  return r,g,b,a
end

local function _GetColor(c) return _ColorSet[c or 0] or _ColorSet[0] end --Get the (rgba) table of a color id.

local _ColorSetLookup = {}
for k,v in ipairs(_ColorSet) do _ColorSetLookup[table.concat(v)] = k end
local function _GetColorID(...) --Get the color id by the (rgba) table.
  local col = {...}
  if col[4] == 0 then return 0 end
  return _ColorSetLookup[table.concat(col)] or 0
end

--Apply transparent colors effect on LIKO12 Images when encoded to PNG
local function _EncodeTransparent(x,y, r,g,b,a)
  if _ImageTransparent[mathFloor(r*255)+1] == 0 then return 0,0,0,0 end
  return r,g,b,a
end

--Convert from LIKO12 palette to real colors.
local function _ExportImage(x,y, r,g,b,a)
  r = mathFloor(r*255)
  if _ImageTransparent[r+1] == 0 then return 0,0,0,0 end
  return colorTo1(_ColorSet[r])
end

--Convert from LIKO-12 palette to real colors ignoring transparent colors.
local function _ExportImageOpaque(x,y, r,g,b,a)
  return colorTo1(_ColorSet[mathFloor(r*255)])
end

local function Verify(value,name,etype,allowNil)
  if type(value) ~= etype then
    if allowNil then
      error(name.." should be a "..etype.." or a nil, provided: "..type(value),3)
    else
      error(name.." should be a "..etype..", provided: "..type(value),3)
    end
  end
  
  if etype == "number" then
    return math.floor(value)
  end
end

--==GPUKit Exports==--
SharedKit.setColor = setColor
SharedKit.getColor = getColor
SharedKit.colorTo1 = colorTo1
SharedKit.colorTo255 = colorTo255
SharedKit.GetColor = _GetColor
SharedKit.GetColorID = _GetColorID
SharedKit.EncodeTransparent = _EncodeTransparent
SharedKit.ExportImage = _ExportImage
SharedKit.ExportImageOpaque = _ExportImageOpaque
SharedKit.Verify = Verify