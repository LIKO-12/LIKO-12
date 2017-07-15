local eapi = select(1,...) --The editor library is provided as an argument

local se = {} --Sprite Editor

local imgw, imgh = 8, 8 --The sprite size (MUST NOT CHANGE)

local fw, fh = fontSize() --A font character size
local swidth, sheight = screenSize() --The screen size
local sheetW, sheetH = math.floor(swidth/imgw), math.floor(sheight/imgh) --The size of the spritessheet in cells (sprites)
local bankH = sheetH/4 --The height of each bank in cells (sprites)
local bsizeH = bankH*imgh --The height of each bank in pixels
local sizeW, sizeH = sheetW*imgw, sheetH*imgh --The size of the spritessheet in pixels

se.SpriteMap = SpriteSheet(imagedata(sizeW,sizeH):image(),sheetW,sheetH) --The spritemap
local mflag = false
local flagsData = "" --A string contain each flag (byte) as a char
for i=1, sheetW*sheetH do flagsData = flagsData..string.char(0) end

--[[The configuration tables scheme:
draw: spriteID, x,y, w,h, spritesheet| OR: x,y, 0, w,h (marked by IMG_DRAW)
rect: x,y, w,h, isline, colorid
grid: gridX,gridY, gridW,gridH, cellW, cellH
slider: x,y, steps, vertical, icon
]]

--SpriteSheet Sprite Selection--
local sprsrecto = {0,sheight-(8+bsizeH+1+1), swidth,bsizeH+2, false, 0} --SpriteSheet Outline Rect
local sprsdraw = {0,sheight-(8+bsizeH+1), 0, 1,1} --SpriteSheet Draw Location; IMG_DRAW
local sprsgrid = {sprsdraw[1],sprsdraw[2], sizeW,bsizeH, sheetW,bankH} --The SpriteSheet selection grid
local sprssrect = {sprsrecto[1]-1,sprsrecto[2], imgw+2,imgh+2, true, 7} --SpriteSheet Select Rect (that white box on the selected sprite)
local sprsbanksgrid = {swidth-(4*8+2),sprsrecto[2]-8, 8*4,8, 4,1} --The grid of banks selection buttons
local sprsid = 1 --Selected Sprite ID
local sprsmflag = false --Sprite selection mouse flag
local sprsbquads = {} --SpriteSheets 4 BanksQuads
local sprsbank = 1 --Current Selected Bank
for i = 1, 4 do --Create the banks quads
  sprsbquads[i] = se.SpriteMap:image():quad(0,(i*bsizeH-bsizeH),sizeW,bsizeH)
end

local maxSpriteIDCells = tostring(sheetW*sheetH):len() --The number of digits in the biggest sprite id.
local sprsidrect = {sprsbanksgrid[1]-(1+maxSpriteIDCells*(fw+1)+3),sprsbanksgrid[2], 1+maxSpriteIDCells*(fw+1),fh+2, false, 6, 13} --The rect of sprite id; The extra argument is the color of number print
local revdraw = {sprsidrect[1]-(imgw+1),sprsrecto[2]-(imgh+1), imgw, imgh} --The small image at the right of the id with the actual sprite size

--The current sprite flags--
local flagsgrid = {swidth-(8*7+1),revdraw[2]-8-1, 8*7,6, 8,1} --The sprite flags grid
local flagsdraw = {flagsgrid[1]-1,flagsgrid[2]-1} --The position of the first (leftmost) flag

--Tools Selection--
local toolsdraw = {104, revdraw[1]-(8*5+4),revdraw[2], 5,1, 1,1,false, eapi.editorsheet} --Tools draw arguments
local toolsgrid = {toolsdraw[2],toolsdraw[3], toolsdraw[4]*8,toolsdraw[5]*8, toolsdraw[4],toolsdraw[5]} --Tools Selection Grid
local stool = 1 --Current selected tool id

local tbtimer = 0 --Tool selection blink timer
local tbtime = 0.1125 --The blink time
local tbflag = false --Is the blink timer activated ?

--Transformations Selection--
local transdraw = {109, flagsgrid[1]-(8*5+3),toolsdraw[3]-(8+3), 5,1, 1,1,false, eapi.editorsheet} --Transformations draw arguments
local transgrid = {transdraw[2],transdraw[3], transdraw[4]*8, transdraw[5]*8, transdraw[4], transdraw[5]} --Transformations Selection Grid
local strans --Selected Transformation

local transtimer --The transformation blink timer
local transtime = 0.1125 --The blink time

--The Sprite (That you are editing--
--Temp is a variables used to hold values while calculating positions
local temp = {SmallestX = transgrid[1] < toolsgrid[1] and transgrid[1] or toolsgrid[1]}
temp.smallestDistance = sprsrecto[2]-8 < temp.SmallestX and sprsrecto[2]-8 or temp.SmallestX
temp.size = math.floor((temp.smallestDistance-(3+3))/(imgw > imgh and imgw or imgh))
if temp.size % 2 == 1 then temp.size = temp.size - 1 end

local psize = temp.size--9 --Zoomed pixel size
local imgdraw = {3,8+3, 0, psize,psize} --Image Location; IMG_DRAW
local imgrecto = {imgdraw[1]-1,imgdraw[2]-1,psize*imgw+2,psize*imgh+2, false,0} --The image outline rect position
local imggrid = {imgdraw[1],imgdraw[2], psize*imgw,psize*imgh, imgw,imgh} --The image drawing grid
local imgquad = se.SpriteMap.img:quad(0,0,imgw,imgh) --The sprite quad

--The Color Selection Pallete--
temp = {col=-1,height=transdraw[3]-(8+3+3)} --Temporary Variable
local palpsize = math.floor(temp.height/4) --The size of each color box in the color selection pallete
local palimg = imagedata(4,4):map(function() temp.col = temp.col + 1 return temp.col end ):image() --The image of the color selection pallete
local palrecto = {swidth-(palpsize*4+3+1),8+3-1, palpsize*4+2,palpsize*4+2, false, 0} --The outline rectangle of the color selection pallete
local paldraw = {palrecto[1]+1,palrecto[2]+1,0,palpsize,palpsize} --The color selection pallete draw arguments; IMG_DRAW
local palgrid = {paldraw[1],paldraw[2],palpsize*4,palpsize*4,4,4} --The color selection pallete grid

local colsrectL = {palrecto[1],palrecto[2],palpsize+2,palpsize+2, true, 7} --The color select box for the left mouse button (The black one)
local colsrectR = {paldraw[1],paldraw[2],palpsize,palpsize, true, 0} --The color select box for the right mouse button (The white one)
local colsL = 0 --Selected Color for the left mouse
local colsR = 0 --Selected Color for the right mouse

--Zoom Slider--
local zoom = 1 --The current zoom level
local zscale = 1 --The current zoom scaling factor
local zflag = "none" --Zoom mouse flag
local zslider = {(imgrecto[1] + imgrecto[3] + palrecto[1])/2 - (4*8)/2, imgrecto[2]+2, 3, false, 186} --The Zoom Slider Draw
local zgrid = {zslider[1]+8,zslider[2]+2,8*zslider[3],4,zslider[3],1} --The Zoom Slider Mouse Grid

--Info system variables--
local infotimer = 0 --The info timer, 0 if no info.
local infotext = "" --The info text to display

--The tools code--
local toolshold = {true,true,false,false,false} --Is it a button (Clone, Stamp, Delete) or a tool (Pencil, fill)
local tools = {
  function(self,cx,cy,b) --Pencil (Default)
    local data = self.SpriteMap:data()
    local qx,qy = self.SpriteMap:rect(sprsid)
    local col = (b == 2 or isMDown(2)) and colsR or colsL
    data:setPixel(qx+cx-1,qy+cy-1,col)
    self.SpriteMap.img = data:image()
  end,

  function(self,cx,cy,b) --Fill (Bucket)
    local data = self.SpriteMap:data()
    local qx,qy = self.SpriteMap:rect(sprsid)
    local col = (b == 2 or isMDown(2)) and colsR or colsL
    local tofill = data:getPixel(qx+cx-1,qy+cy-1)
    if tofill == col then return end
    local size = 8*zscale - 1
    local function spixel(x,y) if x >= qx and x <= qx+size and y >= qy and y <= qy+size then data:setPixel(x,y,col) end end
    local function gpixel(x,y) if x >= qx and x <= qx+size and y >= qy and y <= qy+size then return data:getPixel(x,y) else return false end end
    local function mapPixel(x,y)
      if gpixel(x,y) and gpixel(x,y) == tofill then spixel(x,y) end
      if gpixel(x+1,y) and gpixel(x+1,y) == tofill then mapPixel(x+1,y) end
      if gpixel(x-1,y) and gpixel(x-1,y) == tofill then mapPixel(x-1,y) end
      if gpixel(x,y+1) and gpixel(x,y+1) == tofill then mapPixel(x,y+1) end
      if gpixel(x,y-1) and gpixel(x,y-1) == tofill then mapPixel(x,y-1) end
    end
    mapPixel(qx+cx-1,qy+cy-1)
    self.SpriteMap.img = data:image()
  end,

  function(self) --Clone (Copy)
    self:copy()
  end,

  function(self) --Stamp (Paste)
    self:paste()
  end,

  function(self) --Delete (Erase)
    local data = self.SpriteMap:data()
    local qx,qy = self.SpriteMap:rect(sprsid)
    local size = 8*zscale - 1
    for px = 0, size do for py = 0, size do
      data:setPixel(qx+px,qy+py,0)
    end end
    self.SpriteMap.img = data:image()
    infotimer, infotext = 2,"DELETED SPRITE "..sprsid se:redrawINFO()
  end
}

local function extractSprite()
  local quadx, quady, quadw, quadh = imgquad:getViewport()
  return imagedata(quadw, quadh):paste(se.SpriteMap.img:data(),0,0,quadx,quady,quadw,quadh)
end

--The transformations code--
local function transform(tfunc)
  local current = extractSprite()
  local new = imagedata(current:width(),current:height())
  current:map(function(x,y,c)
    local nx,ny,nc = tfunc(x,y,c,current:width(),current:height())
    new:setPixel(nx or x,ny or y,nc or c)
  end)
  local x,y = se.SpriteMap:rect(sprsid)
  local data = se.SpriteMap:data()
  data:paste(new,x,y)
  se.SpriteMap.img = data:image()
end

local transformations = {
  function(x,y,c,w,h) return h-y-1,x end, --Rotate right
  function(x,y,c,w,h) return y, w-x-1 end, --Rotate left
  function(x,y,c,w,h) return w-x-1,y end, --Flip horizental
  function(x,y,c,w,h) return x,h-y-1 end, --Flip vertical
  function(x,y,c,w,h) return w-x-1,h-y-1 end --Flip horizentaly + verticaly
}

local function drawSlider(pos,x,y,steps,vertical,icon)
  palt(0,false)
  pos = math.floor(pos)
  if icon then eapi.editorsheet:draw(icon,x,y) end
  if vertical then
    
  else
    for sx=1,steps do
      local sprite = 188
      if sx == 1 then sprite = 187 elseif sx == steps then sprite = 189 end
      eapi.editorsheet:draw(sprite,x+sx*8,y)
    end
    
    palt()
    
    eapi.editorsheet:draw(185,x+pos*8,y)
  end
end

function se:entered()
  eapi:drawUI()
  self:_redraw()
end

function se:leaved()
  
end

function se:getImage()
 return self.SpriteMap
end

function se:getFlags()
 return flagsData
end

function se:exportImage()
 return self.SpriteMap:data():encode()
end

function se:exportFlags()
 local fdata = ""
 for char in string.gmatch(flagsData,".") do
  fdata = fdata..";"..string.format("%X",string.byte(char))
 end
 return fdata
end

function se:export(imageonly)
  local data = self:exportImage()
  if imageonly then return data else
    local fdata = self:exportFlags()
    return data.."\n"..fdata
  end
end

function se:import(data)
  if data then
    data = data:gsub("\n","")
    local w,h,imgdata, fdata = string.match(data,"LK12;GPUIMG;(%d+)x(%d+);(.-);(.+)")
    flagsData, fdata = "", ";"..fdata:gsub(";",";;")..";"
    for flag in fdata:gmatch(";(%x+);") do
      flagsData = flagsData..string.char(tonumber(flag,16))
    end
    if flagsData:len() < sheetW*sheetH then
      local missing = sheetW*sheetH - flagsData:len()
      local zerochar = string.char(0)
      for i=1,missing do
        flagsData = flagsData..zerochar
      end
    end
    imgdata = imgdata:sub(0,w*h)
    imgdata = "LK12;GPUIMG;"..w.."x"..h..";"..imgdata
    self.SpriteMap = SpriteSheet(imagedata(imgdata):image(),sheetW,sheetH)
  else
    local flagsData = ""
    for i=1, sheetW*sheetH do flagsData = flagsData..string.char(0) end
    self.SpriteMap = SpriteSheet(imagedata(sizeW,sizeH):image(),sheetW,sheetH)
  end
end

function se:copy()
  local headerlen = 15 + (tostring(8*zscale):len()*2)
  clipboard(string.lower(extractSprite():encode():gsub("\n",""):sub(headerlen,-1)))
  infotimer = 2 --Show info for 2 seconds
  infotext = "COPIED SPRITE "..sprsid
  self:redrawINFO()
end

function se:paste()
  local ok, err = pcall(function()
    local dx,dy,dw,dh = self.SpriteMap:rect(sprsid)
    local sheetdata = self.SpriteMap:data()
    local data = clipboard()
    if data:sub(1,5) == "[gfx]" then -- PICO-8 Paste
      data = data:sub(6,-7) --Remove the start and end tags
      local width = tonumber(data:sub(1,2),16)
      local height = tonumber(data:sub(3,4),16)
      data = string.upper(data:sub(5,-1))
      data = "LK12;GPUIMG;" .. width.."x"..height ..";".. string.upper(data)
    else
      data = data:gsub("%X","")
      local size = math.sqrt(data:len())
      if math.floor(size) ~= size then error("Invalid Data") end
      if size == 0 then error("Empty Data") end
      if size < 8 then error("Too small to paste") end
      data = "LK12;GPUIMG;" .. size.."x"..size ..";".. string.upper(data)
    end
    local sprdata = imagedata(data)
    sheetdata:paste(sprdata,dx,dy)
    self.SpriteMap.img = sheetdata:image()
    self:_redraw()
  end)
  if not ok then
    infotimer = 5 --Display error msg for 5 seconds
    infotext = "PASTE ERR: "..(err or "nil")
    cprint("PASTE ERR: "..(err or "nil"))
  else
    infotimer = 2 --Display info for 2 seconds
    infotext = "PASTED TO SPRITE "..sprsid
  end
  self:redrawINFO()
end

function se:redrawCP() --Redraw color pallete
  rect(palrecto)
  palimg:draw(unpack(paldraw))
  rect(colsrectR)
  rect(colsrectL)
end

function se:redrawSPRS() _ = nil
  rect(sprsrecto)
  self.SpriteMap:image():draw(sprsdraw[1],sprsdraw[2], sprsdraw[3], sprsdraw[4],sprsdraw[5], sprsbquads[sprsbank])
  clip(sprsrecto) rect(sprssrect) clip()
  rect(sprsidrect)
  color(sprsidrect[7])
  local id = ""; for i=1, maxSpriteIDCells-(tostring(sprsid):len()) do id = id .. "0" end; id = id .. tostring(sprsid)
  print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  SpriteGroup(97,sprsbanksgrid[1],sprsbanksgrid[2],sprsbanksgrid[5],sprsbanksgrid[6],1,1,false,eapi.editorsheet)
  eapi.editorsheet:draw(sprsbank+72,sprsbanksgrid[1]+(sprsbank-1)*8,sprsbanksgrid[2])
end

function se:redrawSPR()
  rect(imgrecto)
  self.SpriteMap:image():draw(imgdraw[1],imgdraw[2],imgdraw[3],imgdraw[4],imgdraw[5],imgquad)
  rect(revdraw[1],revdraw[2], revdraw[3],revdraw[4] ,false,0)
  self.SpriteMap:image():draw(revdraw[1],revdraw[2], 0, 1,1, self.SpriteMap:quad(sprsid))
end

function se:redrawZSlider()
  drawSlider(zoom,unpack(zslider))
end

function se:redrawTOOLS()
  --Tools
  SpriteGroup(unpack(toolsdraw))
  eapi.editorsheet:draw((toolsdraw[1]+(stool-1))-24, toolsdraw[2]+(stool-1)*8,toolsdraw[3], 0, toolsdraw[6],toolsdraw[7])
  
  --Transformations
  SpriteGroup(unpack(transdraw))
  if strans then eapi.editorsheet:draw((transdraw[1]+(strans-1))-24, transdraw[2]+(strans-1)*8,transdraw[3], 0, transdraw[6],transdraw[7]) end
end

function se:redrawFLAG()
  local flags = string.byte(flagsData:sub(sprsid,sprsid))
  for i=1,8 do --Bit number
    if bit.band(bit.rshift(flags,i-1),1) == 1 then
      eapi.editorsheet:draw(125+i,flagsdraw[1]+(i-1)*7,flagsdraw[2]) --It's ON
    else
      eapi.editorsheet:draw(125,flagsdraw[1]+(i-1)*7,flagsdraw[2])--It's OFF
    end
  end
end

function se:redrawINFO()
  rect(0,sheight-8,swidth,8,false,9)
  if infotimer > 0 then
    color(4)
    print(infotext or "",1,sheight-6)
  end
end

function se:_redraw()
  self:redrawCP()
  self:redrawSPR()
  self:redrawSPRS()
  self:redrawZSlider()
  self:redrawFLAG()
  self:redrawTOOLS()
end

function se:update(dt)
  if tbflag then
    tbtimer = tbtimer + dt
    if tbtime <= tbtimer then
      stool = tbflag
      tbflag = false
      self:redrawTOOLS()
    end
  end
  
  if transtimer then
    transtimer = transtimer + dt
    if transtimer > transtime then
      transtimer, strans = nil, nil
      self:redrawTOOLS()
    end
  end
  
  if infotimer > 0 then
    infotimer = infotimer - dt
    if infotimer < 0 then
      infotimer = 0
      self:redrawINFO()
    end
  end
end

function se:updateZoom()
  zscale = 2^(zoom-1)
  
  --Update the selection box size
  sprssrect[3] = zscale*8 + 2
  sprssrect[4] = zscale*8 + 2
  
  --Update the selection box position
  local cx, cy = (sprssrect[1]+1)/8 +1, (sprssrect[2]-sprsrecto[2])/8 +1
  cx, cy = math.min(cx-1,sprsgrid[5]-zscale), math.min(cy-1,sprsgrid[6]-zscale)
  sprsid = cy*sheetW+cx+1+(sprsbank*sheetW*bankH-sheetW*bankH)
  sprssrect[1] = cx*8-1
  sprssrect[2] = sprsrecto[2]+cy*8
  
  --Update the quad
  imgquad:setViewport(cx*8,cy*8 + (sprsbank-1)*bsizeH,imgw*zscale,imgh*zscale)
  
  --Update the drawing box
  imgdraw[4], imgdraw[5] = psize/zscale, psize/zscale
  imggrid[5], imggrid[6] = imgw*zscale, imgh*zscale
end

function se:mousepressed(x,y,b,it)
  if isKDown("lshift","rshift") then b = 2 end
  --Pallete Color Selection
  local cx, cy = whereInGrid(x,y,palgrid)
  if cx then
    if b == 1 then
      colsL = ((cy-1)*4+cx)-1
      local cx, cy = cx-1, cy-1
      colsrectL[1] = palrecto[1] + cx*palpsize
      colsrectL[2] = palrecto[2] + cy*palpsize
    elseif b == 2 then
      colsR = ((cy-1)*4+cx)-1
      local cx, cy = cx-1, cy-1
      colsrectR[1] = paldraw[1] + cx*palpsize
      colsrectR[2] = paldraw[2] + cy*palpsize
    end
    
    self:redrawCP()
  end
  
  --Bank selection
  local cx = whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = math.floor((sprsid-1)/(sheetW*bankH))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*sheetW*bankH elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*sheetW*bankH end
    self:updateZoom() self:redrawSPRS() self:redrawSPR() self:redrawFLAG()
  end
  
  --Sprite Selection
  local cx, cy = whereInGrid(x,y,sprsgrid)
  if cx then
    local cx, cy = math.min(cx-1,sprsgrid[5]-zscale), math.min(cy-1,sprsgrid[6]-zscale)
    sprsid = cy*sheetW+cx+1+(sprsbank*sheetW*bankH-sheetW*bankH)
    sprssrect[1] = cx*8 -1
    sprssrect[2] = sprsrecto[2]+cy*8
    imgquad:setViewport(cx*8,cy*8 + (sprsbank-1)*bsizeH,imgw*zscale,imgh*zscale)
    
    self:redrawSPRS() self:redrawSPR() self:redrawFLAG() sprsmflag = true
  end
  
  --Zoom Slider
  local cx, cy = whereInGrid(x,y,zgrid)
  if cx then
    zflag = "down"
    zoom = cx; self:updateZoom()
    cursor("handpress")
    self:redrawSPRS() self:redrawSPR() self:redrawFLAG() self:redrawZSlider()
  end
  
  --Tool Selection
  local cx, cy = whereInGrid(x,y,toolsgrid)
  if cx then
    if toolshold[cx] then
      stool = cx
      self:redrawTOOLS()
      self:redrawSPRS() self:redrawSPR()
    else
      tools[cx](self)
      tbflag, tbtimer = stool, 0
      stool = cx
      self:redrawSPRS() self:redrawSPR() self:redrawTOOLS()
    end
  end
  
  --Transformation Selection
  local cx, cy = whereInGrid(x,y,transgrid)
  if cx and transformations[cx] then
    transform(transformations[cx]) transtimer, strans = 0, cx
    self:redrawSPRS() self:redrawSPR() self:redrawTOOLS()
  end
  
  --Image Drawing
  local cx, cy = whereInGrid(x,y,imggrid)
  if cx then
    if not it then mflag = true end
    tools[stool](self,cx,cy,b)
    self:redrawSPR() self:redrawSPRS()
  end
  
  --Setting Flags
  local cx, cy = whereInGrid(x,y,flagsgrid)
  if cx then
    local flags = string.byte(flagsData:sub(sprsid))
    flags = bit.bxor(flags,bit.lshift(1,cx-1))
    flagsData = flagsData:sub(0,sprsid-1)..string.char(flags)..flagsData:sub(sprsid+1,-1)
    self:redrawFLAG()
  end
end

function se:mousemoved(x,y,dx,dy,it)
  --Image Drawing
  if (not it and mflag) or it then
    local cx, cy = whereInGrid(x,y,imggrid)
    if cx then
      tools[stool](self,cx,cy,isKDown("lshift","rshift") and 2 or false)
      self:redrawSPR() self:redrawSPRS()
    end
  end
  
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      local cx, cy = math.min(cx-1,sprsgrid[5]-zscale), math.min(cy-1,sprsgrid[6]-zscale)
      sprsid = cy*sheetW+cx+1+(sprsbank*sheetW*bankH-sheetW*bankH)
      sprssrect[1] = cx*8-1
      sprssrect[2] = sprsrecto[2]+cy*8
      imgquad:setViewport(cx*8,cy*8 + (sprsbank-1)*bsizeH,imgw*zscale,imgh*zscale)
      
      self:redrawSPRS() self:redrawSPR() self:redrawFLAG()
    end
  end
  
  --Zoom Slider
  local cx, cy = whereInGrid(x,y,zgrid)
  if cx then
    if zflag == "down" then
      zoom = cx; self:updateZoom()
      self:redrawSPRS() self:redrawSPR() self:redrawFLAG() self:redrawZSlider()
    else
      zflag = "hover"
      cursor("handrelease")
    end
  elseif zflag == "hover" then
    cursor("normal")
    zflag = "none"
  end
end

function se:mousereleased(x,y,b,it)
  if isKDown("lshift","rshift") then b = 2 end
  --Image Drawing
  if (not it and mflag) or it then
    local cx, cy = whereInGrid(x,y,imggrid)
    if cx then
      tools[stool](self,cx,cy,b)
      self:redrawSPR() self:redrawSPRS()
    end
  end
  mflag = false
  
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      local cx, cy = math.min(cx-1,sprsgrid[5]-zscale), math.min(cy-1,sprsgrid[6]-zscale)
      sprsid = cy*sheetW+cx+1+(sprsbank*sheetW*bankH-sheetW*bankH)
      sprssrect[1] = cx*8-1
      sprssrect[2] = sprsrecto[2]+cy*8
      imgquad:setViewport(cx*8,cy*8 + (sprsbank-1)*bsizeH,imgw*zscale,imgh*zscale)
      
      self:redrawSPRS() self:redrawSPR() self:redrawFLAG()
    end
  end
  sprsmflag = false
  
  --Zoom Slider
  local cx, cy = whereInGrid(x,y,zgrid)
  if cx then
    if zflag == "down" then
      zoom = cx; self:updateZoom()
      zflag = "hover"
      cursor("handrelease")
      self:redrawSPRS() self:redrawSPR() self:redrawFLAG() self:redrawZSlider()
    else
      zflag = "hover"
      cursor("handrelease")
    end
  elseif zflag ~= "none" then
    cursor("normal")
    zflag = "none"
  end
end

function se:keypressed(key)
  if key == "[" or key == "]" or key == "{" or key == "}" then
    if isKDown("lshift","rshift") then
      if key == "]" or key == "}" then
        colsR = colsR + 1
        if colsR > 15 then colsR = 0 end
      else
        colsR = colsR - 1
        if colsR < 0 then colsR = 15 end
      end
      local cx = colsR % 4
      local cy = math.floor(colsR/4)
      
      colsrectR[1] = paldraw[1] + cx*palpsize
      colsrectR[2] = paldraw[2] + cy*palpsize
    else
      if key == "]" or key == "}" then
        colsL = colsL + 1
        if colsL > 15 then colsL = 0 end
      else
        colsL = colsL - 1
        if colsL < 0 then colsL = 15 end
      end
      local cx = colsL % 4
      local cy = math.floor(colsL/4)
      
      colsrectL[1] = palrecto[1] + cx*palpsize
      colsrectL[2] = palrecto[2] + cy*palpsize
    end
    
    self:redrawCP()
  end
end

local bank = function(bank)
  return function()
    local idbank = math.floor((sprsid-1)/(sheetW*bankH))+1
    sprsbank = bank
    if idbank > sprsbank then
      sprsid = sprsid-(idbank-sprsbank)*sheetW*bankH
    elseif sprsbank > idbank then
      sprsid = sprsid+(sprsbank-idbank)*sheetW*bankH
    end
    se:redrawSPRS() se:redrawSPR()
  end
end

se.keymap = {
  ["ctrl-c"] = se.copy,
  ["ctrl-v"] = se.paste,
  ["1"] = bank(1), ["2"] = bank(2), ["3"] = bank(3), ["4"] = bank(4),
  ["z"] = function() stool=1 se:redrawTOOLS() end,
  ["x"] = function() stool=2 se:redrawTOOLS() end,
  ["delete"] = function() tools[5](se) se:redrawSPRS() se:redrawSPR() end,
  ["shift-["] = function() se:keypressed("[") end,
  ["shift-]"] = function() se:keypressed("]") end,
}

return se