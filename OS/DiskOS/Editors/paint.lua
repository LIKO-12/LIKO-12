local eapi, img, imgdata = ... --Check C://Programs/paint.lua

local sw, sh = screenSize()

local paint = {}
paint.pal = imagedata(16,1)
paint.pal:map(function(x,y,c) return x end)
paint.pal = paint.pal:image()

function paint:drawPalette()
  self.pal:draw(1,sh-7,0,8,8)
end

function paint:drawImage()
  clip(1,9,sw,sh-8*2)
  img:draw(1,9)
  clip()
end

function paint:entered()
  eapi:drawUI()
  palt(1,false)
  self:drawPalette()
  self:drawImage()
end

function paint:leaved()
  palt(1,true)
end

function paint:import(a,b)
  img, imgdata = a,b
end

function paint:export()
  return imgdata:encode()
end

return paint