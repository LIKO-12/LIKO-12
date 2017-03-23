local eapi = select(1,...)
local MapObj = require("C://Libraries/map")

local t = {}

local imgw, imgh = 8, 8 --The sprite size (MUST NOT CHANGE)

local fw, fh = fontSize() --A font character size
local swidth, sheight = screenSize() --The screen size
local sheetW, sheetH = math.floor(swidth/imgw), math.floor(sheight/imgh) --The size of the spritessheet in cells (sprites)
local bankH = sheetH/4 --The height of each bank in cells (sprites)
local bsizeH = bankH*imgh --The height of each bank in pixels
local sizeW, sizeH = sheetW*imgw, sheetH*imgh --The size of the spritessheet in pixels

local SpriteMap

--SpriteSheet Sprite Selection--
local sprsrecto = {1,sheight-(8+bsizeH+1), swidth,bsizeH+2, false, 1} --SpriteSheet Outline Rect
local sprsdraw = {1,sheight-(8+bsizeH), 0, 1,1} --SpriteSheet Draw Location; IMG_DRAW
local sprsgrid = {sprsdraw[1],sprsdraw[2], sizeW,bsizeH, sheetW,bankH} --The SpriteSheet selection grid
local sprssrect = {sprsrecto[1]-1,sprsrecto[2], imgw+2,imgh+2, true, 8} --SpriteSheet Select Rect (that white box on the selected sprite)
local sprsbanksgrid = {swidth-(4*8+1),sprsrecto[2]-8, 8*4,8, 4,1} --The grid of banks selection buttons
local sprsid = 1 --Selected Sprite ID
local sprsmflag = false --Sprite selection mouse flag
local sprsbquads = {} --SpriteSheets 4 BanksQuads
local sprsbank = 1 --Current Selected Bank
for i = 1, 4 do --Create the banks quads
  sprsbquads[i] = eapi.editorsheet:image():quad(1,(i*bsizeH-bsizeH)+1,sizeW,bsizeH)
end

local maxSpriteIDCells = tostring(sheetW*sheetH):len() --The number of digits in the biggest sprite id.
local sprsidrect = {sprsbanksgrid[1]-(1+maxSpriteIDCells*(fw+1)+3),sprsbanksgrid[2], 1+maxSpriteIDCells*(fw+1),fh+2, false, 7, 14} --The rect of sprite id; The extra argument is the color of number print
local revdraw = {sprsidrect[1]-(imgw+1),sprsrecto[2]-(imgh+1), imgw, imgh} --The small image at the right of the id with the actual sprite size

local mapH = sheetH - (1+2+bankH+1)
local mapW = sheetW

local Map = MapObj(mapW,mapH)

local maprect = {1,10,swidth,mapH*8}
local mapgrid = {1,10,swidth,mapH*8,mapW,mapH}
local mapmflag = false

local bgsprite = eapi.editorsheet:extract(59):image()
local bgquad = bgsprite:quad(1,1,mapW*8,mapH*8)

local mflag = false

--Tools Selection--
local toolsdraw = {138, 3,revdraw[2]-1, 7,1, 1,1,false, eapi.editorsheet} --Tools draw arguments
local toolsgrid = {toolsdraw[2],toolsdraw[3], toolsdraw[4]*8,toolsdraw[5]*8, toolsdraw[4],toolsdraw[5]} --Tools Selection Grid
local stool = 1 --Current selected tool id

local tbtimer = 0 --Tool selection blink timer
local tbtime = 0.1125 --The blink time
local tbflag = false --Is the blink timer activated ?

--The tools code--
local toolshold = {true,true,true,false,false,true,true} --Is it a button (Clone, Stamp, Delete) or a tool (Pencil, fill)
local tools = {
  function(self,state,x,y,cx,cy,dx,dy) --Pencil (Default)
    Map:cell(cx,cy,sprsid)
  end,

  function(self,state,x,y,dx,dy) --Fill (Bucket)
    
  end,
  
  function(self,state,x,y,cx,cy,dx,dy) --Eraser
    Map:cell(cx,cy,0)
  end,
  
  function(self) --Clone (Copy)
    
  end,

  function(self) --Stamp (Paste)
    
  end,

  function(self,state,x,y,dx,dy) --Selection
    
  end,
  
  function(self,state,x,y,dx,dy) --Pan
  
  end
}

function t:export()
  return Map:export()
end

function t:import(data)
  if data then
    Map:import(data)
  else
    Map = MapObj(mapW,mapH)
  end
end

function t:entered()
  SpriteMap = eapi.leditors[3].SpriteMap
  eapi:drawUI()
  self:_redraw()
end

function t:leaved()
  
end

function t:_redraw()
  self:redrawMap()
  self:redrawSPRS()
  self:redrawTOOLS()
end

function t:redrawMap()
  palt(1,false)
  bgsprite:draw(1,9,0,1,1,bgquad)
  --rect(1,9,Map:width()*8,Map:height()*8+2,false,1)
  Map:draw(1,10,false,false,false,false,false,false,SpriteMap)
  palt(1,true)
end

function t:redrawSPRS() _ = nil
  rect(sprsrecto)
  SpriteMap.img:draw(sprsdraw[1],sprsdraw[2], sprsdraw[3], sprsdraw[4],sprsdraw[5], sprsbquads[sprsbank])
  rect(sprssrect)
  rect(sprsidrect)
  color(sprsidrect[7])
  local id = ""; for i=1, maxSpriteIDCells-(tostring(sprsid):len()) do id = id .. "0" end; id = id .. tostring(sprsid)
  print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  rect(revdraw[1],revdraw[2], revdraw[3],revdraw[4] ,false,1)
  SpriteMap:image():draw(revdraw[1],revdraw[2], 0, 1,1, SpriteMap:quad(sprsid))
  SpriteGroup(97,sprsbanksgrid[1],sprsbanksgrid[2],sprsbanksgrid[5],sprsbanksgrid[6],1,1,false,eapi.editorsheet)
  eapi.editorsheet:draw(sprsbank+72,sprsbanksgrid[1]+(sprsbank-1)*8,sprsbanksgrid[2])
end

function t:redrawTOOLS()
  --Tools
  SpriteGroup(unpack(toolsdraw))
  eapi.editorsheet:draw((toolsdraw[1]+(stool-1))-24, toolsdraw[2]+(stool-1)*8,toolsdraw[3], 0, toolsdraw[6],toolsdraw[7])
end

function t:update(dt)
  if tbflag then
    tbtimer = tbtimer + dt
    if tbtime <= tbtimer then
      stool = tbflag
      tbflag = false
      self:redrawTOOLS()
    end
  end
end

function t:mousepressed(x,y,b,it)
  --Sprite Selection
  local cx, cy = whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = sprsrecto[2]+cy*8
    
    self:redrawSPRS() sprsmflag = true
  end
  
  --Bank selection
  local cx = whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = math.floor((sprsid-1)/(sheetW*bankH))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*sheetW*bankH elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*sheetW*bankH end
    self:redrawSPRS()
  end
  
  --Tool Selection
  local cx, cy = whereInGrid(x,y,toolsgrid)
  if cx then
    if toolshold[cx] then
      stool = cx
      self:redrawTOOLS()
    else
      tools[cx](self)
      tbflag, tbtimer = stool, 0
      stool = cx
      self:redrawTOOLS()
    end
  end
  
  --Tools Action
  if isInRect(x,y,maprect) then
    local cx, cy = whereInGrid(x,y,mapgrid)
    if cx then
      if not it then mflag = true end
      tools[stool](self,"press",x,y,cx,cy,0,0)
      self:redrawMap()
    end
  end
  
  --Map
  --[[local cx, cy = whereInGrid(x,y,mapgrid)
  if cx then
    Map:cell(cx,cy,sprsid)
    self:redrawMap() mapmflag = true
  end]]
end

function t:mousemoved(x,y,dx,dy,it)
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sprsrecto[2]+cy*8
      
      self:redrawSPRS()
    end
  end
  
  --Tools Action
  if isInRect(x,y,maprect) then
    local cx, cy = whereInGrid(x,y,mapgrid)
    if cx and (it or mflag) then
      tools[stool](self,"move",x,y,cx,cy,0,0)
      self:redrawMap()
    end
  end
  
  --Map
  --[[local cx, cy = whereInGrid(x,y,mapgrid)
  if cx and mapmflag then
    Map:cell(cx,cy,sprsid)
    
    self:redrawMap()
  end]]
end

function t:mousereleased(x,y,b,it)
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*sheetW+cx+(sprsbank*sheetW*bankH-sheetW*bankH)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = sprsrecto[2]+cy*8
      
      self:redrawSPRS()
    end
  end
  sprsmflag = false
  
  --Tools Action
  if isInRect(x,y,maprect) then
    local cx, cy = whereInGrid(x,y,mapgrid)
    if cx and (it or mflag) then
      tools[stool](self,"release",x,y,cx,cy,0,0)
      self:redrawMap() mflag = false
    end
  end
  
  --Map
  --[[local cx, cy = whereInGrid(x,y,mapgrid)
  if cx and mapmflag then
    Map:cell(cx,cy,sprsid)
    
    self:redrawMap()
  end
  mapmflag = false]]
end

return t