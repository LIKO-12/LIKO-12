return function(img,w,h)
  local ss = {} --The spritesheet object
  
  ss.quads = {} --The sprites quads
  ss.flags = {} --The sprites flags
  
  ss.w, ss.h = w,h --The number of sprites in width and height
  
  if type(img) == "string" then --Sheet data string
    img = img:gsub("\n","") --Remove newline characters.
    
    --Parse the sheetdata
    local imgW,imgH,imgdata, fdata = string.match(img,"LK12;GPUIMG;(%d+)x(%d+);(.-);(.+)")
    
    --Parse the flagsdata
    fdata = ";"..fdata:gsub(";",";;")..";" --Make it easier to parse
    for flag in fdata:gmatch(";(%x+);") do --For each flag
      ss.flags[#ss.flags + 1] = tonumber(flag,16)
    end
    
    --Parse the imagedata
    imgdata = imgdata:sub(0,imgW*imgH) --Remove any extra characters
    imgdata = "LK12;GPUIMG;"..imgW.."x"..imgH..";"..imgdata
    
    ss.img = imagedata(imgdata):image()
  else --Image, Sprite Width, Sprite Height
    ss.img = img
  end
  
  ss.cw, ss.ch = math.floor(ss.img:width()/ss.w), math.floor(ss.img:height()/ss.h) --The size of each sprite
  
  for y=0, ss.h-1 do for x=0, ss.w-1 do
    ss.quads[#ss.quads + 1] = ss.img:quad(x*ss.cw,y*ss.ch,ss.cw,ss.ch)
  end end

  ss.quads[0] = quad(0,0,0,0,0,0) --Null quad, used by the map object for spritebatch mode.
  
  function ss:image() return self.img end
  function ss:data() return self.img:data() end
  function ss:quad(id) return self.quads[math.floor(id)] end
  function ss:rect(id) return self.quads[math.floor(id)]:getViewport() end
  function ss:draw(id,x,y,r,sx,sy) self.img:draw(x,y,r,sx,sy,self.quads[math.floor(id)]) return self end
  function ss:extract(id) return imagedata(self.cw,self.ch):paste(self:data(),0,0,self:rect(math.floor(id))) end
  function ss:flag(id,value)
    id = math.floor(id)
    if value then
      self.flags[id] = value
      return self
    else
      return self.flags[id] or 0
    end
  end
  
  return ss
end