--This file is responsible of generating all the drawing offsets
--It will works by testing on canvases, invisibly to the user.
--[[local ofs = {} --Offsets table.
ofs.point = {0,0} --The offset of GPU.point/s.
ofs.print = {-1,-1} --The offset of GPU.print.
ofs.print_grid = {-1,-1} --The offset of GPU.print with grid mode.
ofs.line_start = {0,0} --The offset of the first coord of GPU.line/s.
ofs.line = {0,0} --The offset of GPU.line/s.
ofs.circle = {0,0,0} --The offset of GPU.circle with l as false (x,y,r).
ofs.circle_line = {0,0,0} --The offset of GPU.circle with l as true (x,y,r).
ofs.ellipse = {0,0,0,0} --The offset of GPU.circle with l as false (x,y,rx,ry).
ofs.ellipse_line = {0,0,0,0} --The offset of GPU.circle with l as true (x,y,rx,ry).
ofs.rect = {-1,-1} --The offset of GPU.rect with l as false.
ofs.rectSize = {0,0} --The offset of w,h in GPU.rect with l as false.
ofs.rect_line = {0,0} --The offset of GPU.rect with l as true.
ofs.rectSize_line = {-1,-1} --The offset of w,h in GPU.rect with l as false.
ofs.triangle = {0,0} --The offset of each vertices in GPU.triangle with l as false.
ofs.triangle_line = {0,0} --The offset of each vertices in GPU.triangle with l as true.
ofs.polygon = {0,0} --The offset of each vertices in GPU.polygon.
ofs.image = {-1,-1}
ofs.quad = {-1,-1}]]

local ofs = {}

local _Canvas
local imgdata
local function canvas(w,h)
  love.graphics.setCanvas()
  _Canvas = love.graphics.newCanvas(w,h,{dpiscale=1})
  love.graphics.setCanvas(_Canvas)
  love.graphics.clear(0,0,0,1)
end
local function imagedata()
  love.graphics.setCanvas()
  imgdata =  _Canvas:newImageData()
  love.graphics.setCanvas(_Canvas)
end

love.graphics.setDefaultFilter("nearest","nearest")
love.graphics.setLineStyle("rough") --Set the line style.
love.graphics.setLineJoin("miter") --Set the line join style.
love.graphics.setPointSize(1) --Set the point size to 1px.
love.graphics.setLineWidth(1) --Set the line width to 1px.

love.graphics.setColor(1,1,1,1)

--Screen
do
  ofs.screen = {0,0}
end

--Point calibration
do
  canvas(8,8)
  love.graphics.points(4,4)
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      ofs.point = {4-x, 4-y}
    end
    return r,g,b,a
  end)
end

--Print calibration
do
  ofs.print = {0,0} --The offset of GPU.print.
  ofs.print_grid = {0,0} --The offset of GPU.print with grid mode.
end

--Lines calibration
do
  canvas(10,10)
  love.graphics.line(4,4, 6,4, 6,6, 4,6, 4,4)
  local xpos, ypos = 10,10
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if x < xpos then xpos = x end
      if y < ypos then ypos = y end
    end
    return r,g,b,a
  end)
  ofs.line = {4-xpos,4-ypos}
  ofs.line_start = {4-xpos,4-ypos}
end

--Circle calibration
do
  canvas(30,30)
  love.graphics.circle("fill",15,15,19)
  local topy, bottomy = 30,1
  local leftx, rightx = 30,1
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if y < topy then topy = y end
      if y > bottomy then bottomy = y end
      if x < leftx then leftx = x end
      if x > rightx then rightx = x end
    end
    return r,g,b,a
  end)
  local cx = (rightx + leftx +1)/2
  local cy = (topy + bottomy +1)/2
  ofs.circle = {15-cx,15-cy,0}
end

--Circle line calibration
do
  canvas(30,30)
  love.graphics.circle("line",15,15,19)
  local topy, bottomy = 30,1
  local leftx, rightx = 30,1
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if y < topy then topy = y end
      if y > bottomy then bottomy = y end
      if x < leftx then leftx = x end
      if x > rightx then rightx = x end
    end
    return r,g,b,a
  end)
  local cx = (rightx + leftx +1)/2
  local cy = (topy + bottomy +1)/2
  ofs.circle_line = {15-cx,15-cy,0}
end

--Ellipse calibration
do
  canvas(30,30)
  love.graphics.ellipse("fill",15,15,19,19)
  local topy, bottomy = 30,1
  local leftx, rightx = 30,1
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if y < topy then topy = y end
      if y > bottomy then bottomy = y end
      if x < leftx then leftx = x end
      if x > rightx then rightx = x end
    end
    return r,g,b,a
  end)
  local cx = (rightx + leftx +1)/2
  local cy = (topy + bottomy +1)/2
  ofs.ellipse = {15-cx,15-cy,0,0}
end

--Ellipse line calibration
do
  canvas(30,30)
  love.graphics.ellipse("line",15,15,19,19)
  local topy, bottomy = 30,1
  local leftx, rightx = 30,1
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if y < topy then topy = y end
      if y > bottomy then bottomy = y end
      if x < leftx then leftx = x end
      if x > rightx then rightx = x end
    end
    return r,g,b,a
  end)
  local cx = (rightx + leftx +1)/2
  local cy = (topy + bottomy +1)/2
  ofs.ellipse_line = {15-cx,15-cy,0,0}
end

--Rectangle calibration
do
  canvas(10,10)
  love.graphics.rectangle("fill",2,2,6,6)
  local topy, bottomy = 10,1
  local leftx, rightx = 10,1
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if y < topy then topy = y end
      if y > bottomy then bottomy = y end
      if x < leftx then leftx = x end
      if x > rightx then rightx = x end
    end
    return r,g,b,a
  end)
  ofs.rect = {2-leftx,2-topy}
  ofs.rectSize = {6-(rightx-leftx+1),6-(bottomy-topy+1)}
end

--Rectangle line calibration
do
  canvas(10,10)
  love.graphics.rectangle("line",2,2,6,6)
  local topy, bottomy = 10,1
  local leftx, rightx = 10,1
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if y < topy then topy = y end
      if y > bottomy then bottomy = y end
      if x < leftx then leftx = x end
      if x > rightx then rightx = x end
    end
    return r,g,b,a
  end)
  ofs.rect_line = {2-leftx,2-topy}
  ofs.rectSize_line = {6-(rightx-leftx+1),6-(bottomy-topy+1)}
end

--Triangle
do
  ofs.triangle = {0,0} --The offset of each vertices in GPU.triangle with l as false.
  ofs.triangle_line = {0,0} --The offset of each vertices in GPU.triangle with l as true.
end

--Polygone
do
  ofs.polygon = {0,0} --The offset of each vertices in GPU.polygon.
end

--Image
do
  local id = love.image.newImageData(4,4)
  id:mapPixel(function() return 1,1,1,1 end)
  id = love.graphics.newImage(id)
  canvas(10,10)
  love.graphics.draw(id,4,4)
  local leftx, topy = 10,10
  imagedata() imgdata:mapPixel(function(x,y, r,g,b,a)
    if r == 1 and g == 1 and b == 1 and a == 1 then
      if x < leftx then leftx = x end
      if y < topy then topy = y end
    end
    return r,g,b,a
  end)
  ofs.image = {4-leftx,4-topy}
end

--Quad
do
  ofs.quad = ofs.image
end

love.graphics.setCanvas()

return ofs