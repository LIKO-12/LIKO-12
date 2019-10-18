--GPU: Shared Functions.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local SharedVars = GPUVars.Shared

--==Localized Lua Library==--
local mathFloor = math.floor

--==Shared Functions==--
--Wrapper for setColor to use 0-255 values
local function setColor(r,g,b,a)
  if type(r) == "table" then
    r,g,b,a = r[1], r[2], r[3], r[4]
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
  if type(r) == "table" then r,g,b,a = r[1], r[2], r[3], r[4] end
  if r then r = r/255 end
  if g then g = g/255 end
  if b then b = b/255 end
  if a then a = a/255 end
  return r,g,b,a
end

--Convert color from 0-1 to 0-255
local function colorTo255(r,g,b,a)
  if type(r) == "table" then r,g,b,a = r[1], r[2], r[3], r[4] end
  if r then r = mathFloor(r*255) end
  if g then g = mathFloor(g*255) end
  if b then b = mathFloor(b*255) end
  if a then a = mathFloor(a*255) end
  return r,g,b,a
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

--==GPUVars Exports==--
SharedVars.setColor = setColor
SharedVars.getColor = getColor
SharedVars.colorTo1 = colorTo1
SharedVars.colorTo255 = colorTo255
SharedVars.Verify = Verify