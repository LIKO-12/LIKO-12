--GPU: Shapes Drawing.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local lg = love.graphics

local VRamVars = GPUVars.VRam
local SharedVars = GPUVars.Shared
local RenderVars = GPUVars.Render
local CalibrationVars = GPUVars.Calibration

--==Varss Constants==--
local UnbindVRAM = VRamVars.UnbindVRAM
local Verify = SharedVars.Verify
local ofs = CalibrationVars.Offsets

--==GPU Shapes API==--

--Clears the whole screen with black or the given color id.
function GPU.clear(c) UnbindVRAM()
  c = c or 0
  c = Verify(c,"The color id","number",true)
  if c > 15 or c < 0 then return error("The color id is out of range.") end --Error
  lg.clear(c/255,0,0,1) RenderVars.ShouldDraw = true
end

--Draws a point/s at specific location/s, accepts the colorid as the last args, x and y of points must be provided before the colorid.
function GPU.points(...) UnbindVRAM()
  local args = {...} --The table of args
  GPU.pushColor() --Push the current color.
  if not (#args % 2 == 0) then GPU.color(args[#args]) table.remove(args,#args) end --Extract the colorid (if exists) from the args and apply it.
  for k,v in ipairs(args) do Verify(v,"Arg #"..k,"number") end --Error
  for k,v in ipairs(args) do if (k % 2 == 1) then args[k] = v + ofs.point[1] else args[k] = v + ofs.point[2] end end --Apply the offset.
  lg.points(unpack(args)) RenderVars.ShouldDraw = true --Draw the points and tell that changes has been made.
  GPU.popColor() --Pop the last color in the stack.
end
GPU.point = GPU.points --Just an alt name :P.

--Draws a line/s at specific location/s, accepts the colorid as the last args, x1,y1,x2 and y2 of points must be provided before the colorid.
function GPU.lines(...) UnbindVRAM()
  local args = {...} --The table of args
  GPU.pushColor() --Push the current color.
  if not (#args % 2 == 0) then GPU.color(args[#args]) table.remove(args,#args) end --Extract the colorid (if exists) from the args and apply it.
  for k,v in ipairs(args) do if type(v) ~= "number" then return false, "Arg #"..k.." must be a number." end end --Error
  if #args < 4 then return false, "Need at least two vertices to draw a line." end --Error
  args[1], args[2] = args[1] + ofs.line_start[1], args[2] + ofs.line_start[2]
  for k=3, #args do if (k % 2 == 1) then args[k] = args[k] + ofs.line[1] else args[k] = args[k] + ofs.line[2] end end --Apply the offset.
  lg.line(unpack(args)) RenderVars.ShouldDraw = true --Draw the lines and tell that changes has been made.
  GPU.popColor() --Pop the last color in the stack.
end
GPU.line = GPU.lines --Just an alt name :P.

--Draw a rectangle filled, or lines only.
--X pos, Y pos, W width, H height, L linerect, C colorid.
function GPU.rect(x,y,w,h,l,c) UnbindVRAM()
  x,y,w,h,l,c = x, y, w, h, l or false, c --In case if they are not provided.
  
  --It accepts all the args as a table.
  if type(x) == "table" then
    x,y,w,h,l,c = x[1], x[2], x[3], x[4], x[5], x[6]
    l,c = l or false, c --In case if they are not provided.
  end
  
  --Args types verification
  x = Verify(x,"X pos","number")
  y = Verify(y,"Y pos","number")
  w = Verify(w,"Width","number")
  h = Verify(h,"Height","number")
  if c then c = Verify(c,"The color id","number",true) end
  
  if c then --If the colorid is provided, pushColor then set the color.
    GPU.pushColor()
    GPU.color(c)
  end
  
  --Apply the offset.
  if l then
    x,y = x+ofs.rect_line[1], y+ofs.rect_line[2] --Pos
    w,h = w+ofs.rectSize_line[1], h+ofs.rectSize_line[2] --Size
  else
    x,y = x+ofs.rect[1], y+ofs.rect[2] --Pos
    w,h = w+ofs.rectSize[1], h+ofs.rectSize[2] --Size
  end
  
  lg.rectangle(l and "line" or "fill",x,y,w,h) RenderVars.ShouldDraw = true --Draw and tell that changes has been made.
  
  if c then GPU.popColor() end --Restore the color from the stack.
end

--Draws a circle filled, or lines only.
function GPU.circle(x,y,r,l,c,s) UnbindVRAM()
  x,y,r,l,c,s = x, y, r, l or false, c, s --In case if they are not provided.
  
  --It accepts all the args as a table.
  if x and type(x) == "table" then
    x,y,r,l,c,s = x[1], x[2], x[3], x[4], x[5], x[6]
    l,c = l or false, c --In case if they are not provided.
  end
  
  --Args types verification
  x = Verify(x,"X pos","number")
  y = Verify(y,"Y pos","number")
  Verify(r,"Radius","number")
  if c then c = Verify(c,"The color id","number",true) end
  if s then s = Verify(s,"Segments","number",true) end
  
  if c then --If the colorid is provided, pushColor then set the color.
    GPU.pushColor()
    GPU.color(c)
  end
  
  --Apply the offset.
  if l then
    x,y,r = x+ofs.circle_line[1], y+ofs.circle_line[2], r+ofs.circle_line[3]
  else
    x,y,r = x+ofs.circle[1], y+ofs.circle[2], r+ofs.circle[3]
  end
  
  lg.circle(l and "line" or "fill",x,y,r,s) RenderVars.ShouldDraw = true --Draw and tell that changes has been made.
  
  if c then GPU.popColor() end --Restore the color from the stack.
end

--Draws a triangle
function GPU.triangle(x1,y1,x2,y2,x3,y3,l,col) UnbindVRAM()
  x1,y1,x2,y2,x3,y3,l,col = x1,y1,x2,y2,x3,y3,l or false,col --Localize them
  
  if type(x1) == "table" then
    x1,y1,x2,y2,x3,y3,l,col = x1[1], x1[2], x1[3], x1[4], x1[5], x1[6], x1[7], x1[8]
  end
  
  x1 = Verify(x1,"x1","number")
  y1 = Verify(y1,"y1","number")
  x2 = Verify(x2,"x2","number")
  y2 = Verify(y2,"y2","number")
  x3 = Verify(x3,"x3","number")
  y3 = Verify(y3,"y3","number")
  if col then col = Verify(col,"Color","number",true) end
  
  if col and (col < 0 or col > 15) then return error("color is out of range ("..col..") expected [0,15]") end
  if col then GPU.pushColor() GPU.color(col) end
  
  --Apply the offset
  if l then
    x1,y1,x2,y2,x3,y3 = x1 + ofs.triangle_line[1], y1 + ofs.triangle_line[2], x2 + ofs.triangle_line[1], y2 + ofs.triangle_line[2], x3 + ofs.triangle_line[1], y3 + ofs.triangle_line[2]
  else
    x1,y1,x2,y2,x3,y3 = x1 + ofs.triangle[1], y1 + ofs.triangle[2], x2 + ofs.triangle[1], y2 + ofs.triangle[2], x3 + ofs.triangle[1], y3 + ofs.triangle[2]
  end
  
  lg.polygon(l and "line" or "fill", x1,y1,x2,y2,x3,y3)
  
  if col then GPU.popColor() end
end

--Draw a polygon
function GPU.polygon(...) UnbindVRAM()
  local args = {...} --The table of args
  GPU.pushColor() --Push the current color.
  if not (#args % 2 == 0) then GPU.color(args[#args]) table.remove(args,#args) end --Extract the colorid (if exists) from the args and apply it.
  for k,v in ipairs(args) do Verify(v,"Arg #"..k,"number") end --Error
  if #args < 6 then return error("Need at least three vertices to draw a polygon.") end --Error
  for k,v in ipairs(args) do if (k % 2 == 0) then args[k] = v + ofs.polygon[2] else args[k] = v + ofs.polygon[1] end end --Apply the offset.
  lg.polygon("fill",unpack(args)) RenderVars.ShouldDraw = true --Draw the lines and tell that changes has been made.
  GPU.popColor() --Pop the last color in the stack.
end

--Draws a ellipse filled, or lines only.
function GPU.ellipse(x,y,rx,ry,l,c,s) UnbindVRAM()
  x,y,rx,ry,l,c,s = x or 0, y or 0, rx or 1, ry or 1, l or false, c, s --In case if they are not provided.
  
  --It accepts all the args as a table.
  if x and type(x) == "table" then
    x,y,rx,ry,l,c,s = x[1], x[2], x[3], x[4], x[5], x[6], x[7]
  end
  
  --Args types verification
  x = Verify(x,"X coord","number")
  y = Verify(y,"Y coord","number")
  Verify(rx,"X radius","number")
  Verify(ry, "Y radius","number")
  if c then c = Verify(c,"The color id","number",true) end
  if s then s = Verify(s,"Segments","number",true) end
  
  if c then --If the colorid is provided, pushColor then set the color.
    GPU.pushColor()
    GPU.color(c)
  end
  
  --Apply the offset.
  if l then
    x,y,rx,ry = x+ofs.ellipse_line[1], y+ofs.ellipse_line[2], rx+ofs.ellipse_line[3], ry+ofs.ellipse_line[4]
  else
    x,y,rx,ry = x+ofs.ellipse[1], y+ofs.ellipse[2], rx+ofs.ellipse[3], ry+ofs.ellipse[4]
  end
  
  lg.ellipse(l and "line" or "fill",x,y,rx,ry,s) RenderVars.ShouldDraw = true --Draw and tell that changes has been made.
  
  if c then GPU.popColor() end --Restore the color from the stack.
end