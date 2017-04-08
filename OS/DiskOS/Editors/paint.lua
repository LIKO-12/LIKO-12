local eapi, img, imgdata = ... --Check C://Programs/paint.lua

local sw, sh = screenSize()

local paint = {}
paint.pal = imagedata(16,1)
paint.pal:map(function(x,y,c) return x end)
paint.pal = paint.pal:image()

paint.drawCursor = eapi.editorsheet:extract(8):image()

paint.fgcolor, paint.bgcolor = 8,1

paint.palGrid = {sw-16*8+1,sh-7,16*8,8,16,1}

function paint:drawPalette()
  self.pal:draw(sw-16*8+1,sh-7,0,8,8)
end

function paint:drawColorCell()
  palt(1,true)
  pal(9,self.fgcolor)
  pal(13,self.bgcolor)
  eapi.editorsheet:draw(77,sw-16*8-8+1,sh-7)
  pal()
  palt(1,false)
end

function paint:drawImage()
  clip(1,9,sw,sh-8*2)
  img:draw(1,9)
  clip()
end

function paint:drawBottomBar()
  eapi:drawBottomBar()
  self:drawPalette()
  self:drawColorCell()
end

function paint:entered()
  eapi:drawUI()
  palt(1,false)
  self:drawPalette()
  self:drawColorCell()
  self:drawImage()
  local mx, my = getMPos()
  self:mousemoved(mx,my,0,0,isMobile())
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

function paint:update(dt)
  
end

function paint:mousepressed(x,y,b,istouch)
  local cx, cy = whereInGrid(x,y,self.palGrid)
  if cx then
    if b == 1 then
      self.fgcolor = cx
    elseif b == 2 then
      self.bgcolor = cx
    end
    self:drawColorCell()
  end
end

function paint:mousemoved(x,y,dx,dy,istouch)
  if isInRect(x,y,{1,9,sw,sh-8*2}) then
    if istouch then
      cursor("draw")
    else
      cursor("none")
      eapi:drawBackground(); self:drawImage()
      eapi:drawTopBar(); self:drawBottomBar()
      palt(1,true)
      self.drawCursor:draw(x-3,y-3)
      palt(1,false)
    end
  else
    if cursor() == "none" then eapi:drawBackground(); self:drawImage(); eapi:drawTopBar(); self:drawBottomBar() end
    if cursor() == "none" or cursor() == "draw" then cursor("normal") end
  end
end

return paint