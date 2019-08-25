--GPU: ImageData Object.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local SharedVars = GPUVars.Shared

--==Varss Constants==--
local Verify = SharedVars.Verify

function GPU.fontdata(cw,ch)
  
  local fdata --FontData to load
  
  if type(cw) == "string" then
    if cw:sub(0,13) == "LK12;GPUFONT;" then
      cw = cw:gsub("\r",""):gsub("\n","")
      cw, ch, fdata = string.match(cw,"LK12;GPUFONT;(%d+)x(%d+);(.+)")
      cw, ch = tonumber(cw), tonumber(ch)
    else
      return error("Invalid fontdata string")
    end
  end
  
  cw = Verify(cw,"characterWidth","number")
  ch = Verify(ch,"characterHeight","number")
  
  local fontImageWidth = (cw+1)*255
  local fontImageHeight = ch
  
  local fontImage = love.image.newImageData(fontImageWidth, fontImageHeight)
  
  if fdata then
    local fdataIter = fdata:gmatch(".")
    fontImage:mapPixel(function(x,y)
      local fdchar = fdataIter() or ""
      
      if fdchar == "#" then
        return 1,1,1,1
      else
        return 0,0,0,0
      end
    end)
  end
  
  --Setup characters seperator
  for cn=0,254 do fontImage:setPixel(cn*(cw+1),0, 1,0,0,1) end
  
  local f = {}
  
  function f:width() return cw end
  function f:height() return ch end
  function f:size() return cw, ch end
  
  function f:setPixel(charByte,x,y,bool)
    charByte = Verify(charByte,"characterByte","number")
    if charByte < 1 or charByte > 255 then return error("characterByte is out of range ("..charByte.."), expected [1,255]") end
    x = Verify(x,"x","number")
    y = Verify(y,"y","number")
    if x < 0 or x >= cw then return error("X is out of range ("..x.."), expected [0,"..(cw-1).."]") end
    if y < 0 or y >= ch then return error("Y is out of range ("..y.."), expected [0,"..(ch-1).."]") end
    
    local p = bool and 1 or 0
    fontImage:setPixel((charByte-1)*(cw+1)+1+x,y, p,p,p,p)
    
    return self
  end
  
  function f:getPixel(charByte,x,y)
    charByte = Verify(charByte,"characterByte","number")
    if charByte < 1 or charByte > 255 then return error("characterByte is out of range ("..charByte.."), expected [1,255]") end
    x = Verify(x,"x","number")
    y = Verify(y,"y","number")
    if x < 0 or x >= cw then return error("X is out of range ("..x.."), expected [0,"..(cw-1).."]") end
    if y < 0 or y >= ch then return error("Y is out of range ("..y.."), expected [0,"..(ch-1).."]") end
    
    local _, p = fontImage:getPixel((charByte-1)*(cw+1)+1+x,y)
    
    return (p == 1)
  end
  
  function f:encode()
    local fstr, fpos = {string.format("LK12;GPUFONT;%dx%d;",cw,ch)}, 2
    
    fontImage:mapPixel(function(x,y,r,g,b,a)
      if x == 0 then
        fstr[fpos] = "|\n"
        fpos = fpos + 1
      end
      
      if x%(cw+1) == 0 then
        fstr[fpos] = "|"
      else
        fstr[fpos] = (g == 1) and "#" or "-"
      end
      fpos = fpos + 1
      
      return r,g,b,a
    end)

    fstr[fpos] = "|"
    fstr = table.concat(fstr)
    
    return fstr
  end
  
  return f
  
end