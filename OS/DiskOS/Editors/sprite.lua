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
local toolsdraw = {104, 2,revdraw[2]-1, 5,1, 1,1,false, eapi.editorsheet} --Tools draw arguments
local toolsgrid = {toolsdraw[2],toolsdraw[3], toolsdraw[4]*8,toolsdraw[5]*8, toolsdraw[4],toolsdraw[5]} --Tools Selection Grid
local stool = 1 --Current selected tool id

local tbtimer = 0 --Tool selection blink timer
local tbtime = 0.1125 --The blink time
local tbflag = false --Is the blink timer activated ?

--Transformations Selection--
local transdraw = {109, toolsdraw[2] + toolsdraw[4]*8 + 3,toolsdraw[3], 5,1, 1,1,false, eapi.editorsheet} --Transformations draw arguments
local transgrid = {transdraw[2],transdraw[3], transdraw[4]*8, transdraw[5]*8, transdraw[4], transdraw[5]} --Transformations Selection Grid
local strans --Selected Transformation

local transtimer --The transformation blink timer
local transtime = 0.1125 --The blink time

--The Sprite (That you are editing--
--Temp is a variables used to hold values while calculating positions

local psize = 8--Zoomed pixel size
local imgdraw = {2,8+2, 0, psize,psize} --Image Location; IMG_DRAW
local imgrecto = {imgdraw[1]-1,imgdraw[2]-1,psize*imgw+2,psize*imgh+2, false,0} --The image outline rect position
local imggrid = {imgdraw[1],imgdraw[2], psize*imgw,psize*imgh, imgw,imgh} --The image drawing grid
local imgquad = se.SpriteMap.img:quad(0,0,imgw,imgh) --The sprite quad

--The Color Selection Pallete--
temp = {col=-1,height=flagsdraw[2]-(8+3+3)} --Temporary Variable
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
local zslider = {(transdraw[2] + transdraw[4]*8 + revdraw[1])/2 - (4*8)/2, transdraw[3]+1, 3, false, 186} --The Zoom Slider Draw
local zgrid = {zslider[1]+8,zslider[2]+2,8*zslider[3],4,zslider[3],1} --The Zoom Slider Mouse Grid

--Size Slider
local size = 1 --The current zoom level
local sscale = 1 --The current zoom scaling factor
local sflag = "none" --Zoom mouse flag
local sslider = {(imgrecto[1]+imgrecto[3]+palrecto[1])/2 - (8*5)/2, paldraw[2], 4, false, 120} --The Size Slider Draw
local sgrid = {sslider[1]+8,sslider[2]+2,8*sslider[3],4,sslider[3],1} --The Size Slider Mouse Grid
local sizes = {1,2,3,5} --Brush sizes
--The tools code--
local toolshold = {true,true,false,false,false} --Is it a button (Clone, Stamp, Delete) or a tool (Pencil, fill)
local tools = {
  function(self,cx,cy,b) --Pencil (Default)
    local data = self.SpriteMap:data()
    local qx,qy = self.SpriteMap:rect(sprsid)
    local col = (b == 2) and colsR or colsL

    local s = sizes[size]

    for x=-math.floor(s/2),math.ceil(s/2-1) do
      for y=-math.floor(s/2),math.ceil(s/2-1) do
        if cx+x >= 1 and cx+x <= 8*zscale and cy+y >= 1 and cy+y <= 8*zscale then
          data:setPixel(qx+cx-1+x,qy+cy-1+y,col)
        end
      end
    end

    self.SpriteMap.img = data:image()
  end,

  function(self,cx,cy,b) --Fill (Bucket)
    local data = self.SpriteMap:data()
    local qx,qy = self.SpriteMap:rect(sprsid)
    local col = (b == 2) and colsR or colsL
    local size = 8*zscale - 1

    ImageUtils.queuedFill(data, qx+cx-1,qy+cy-1, col, qx,qy, qx+size,qy+size)
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
    _systemMessage("DELETED SPRITE "..sprsid, 2)
  end
}

local function extractSprite()
  local quadx, quady, quadw, quadh = imgquad:getViewport()
  return imagedata(quadw, quadh):paste(se.SpriteMap.img:data(),0,0,quadx,quady,quadw,quadh)
end

--The transformations code--
local transformations = {
  function(x,y,c,w,h) return h-y-1,x end, --Rotate right
  function(x,y,c,w,h) return y, w-x-1 end, --Rotate left
  function(x,y,c,w,h) return w-x-1,y end, --Flip horizental
  function(x,y,c,w,h) return x,h-y-1 end, --Flip vertical
  function(x,y,c,w,h) return w-x-1,h-y-1 end --Flip horizentaly + verticaly
}

local function transform(tnum)
  local tfunc = transformations[tnum]; transtimer, strans = 0, tnum
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
  se:redrawSPRS() se:redrawSPR() se:redrawTOOLS()
end

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

function se:getSheet()
  return self.SpriteMap
end

function se:getFlags()
  return flagsData
end

function se:getSelectedColors()
  return colsL, colsR
end

function se:getSelectedSprite()
  return extractSprite()
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

function se:encode()
  return BinUtils.imgToBin(self.SpriteMap:data())..flagsData
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

function se:decode(data)
  local imgbin = data:sub(1,(swidth*sheight)/2)
  flagsData = data:sub((swidth*sheight)/2+1,-1)
  BinUtils.binToImg(self.SpriteMap:data(),imgbin)
  self.SpriteMap:image():refresh()
end

function se:copy()
  local headerlen = 15 + (tostring(8*zscale):len()*2)
  clipboard(string.lower(extractSprite():encode():gsub("\n",""):sub(headerlen,-1)))
  _systemMessage("COPIED SPRITE "..sprsid,2)
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
    _systemMessage("PASTE ERR: "..(err or "nil"),5)
    cprint("PASTE ERR: "..(err or "nil"))
  else
    _systemMessage("PASTED TO SPRITE "..sprsid,2)
  end
end

--Redraw color pallete
function se:redrawCP()
  rect(palrecto)
  palimg:draw(unpack(paldraw))
  rect(colsrectR)
  rect(colsrectL)
end

--Redraw sprite selection
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

--Redraw the sprite editing rectangle
  function se:redrawSPR()
    rect(imgrecto)
    self.SpriteMap:image():draw(imgdraw[1],imgdraw[2],imgdraw[3],imgdraw[4],imgdraw[5],imgquad)
    rect(revdraw[1],revdraw[2], revdraw[3],revdraw[4] ,false,0)
    self.SpriteMap:image():draw(revdraw[1],revdraw[2], 0, 1,1, self.SpriteMap:quad(sprsid))
  end

--Redraw the zooming slider
  function se:redrawZSlider()
    drawSlider(zoom,unpack(zslider))
  end

--Redraw the size slider
  function se:redrawSSlider()
    sslider[5] = 120 + size
    drawSlider(size,unpack(sslider))
  end

--Redraw the tools selection bar
  function se:redrawTOOLS()
    --Tools
    SpriteGroup(unpack(toolsdraw))
    eapi.editorsheet:draw((toolsdraw[1]+(stool-1))-24, toolsdraw[2]+(stool-1)*8,toolsdraw[3], 0, toolsdraw[6],toolsdraw[7])

    --Transformations
    SpriteGroup(unpack(transdraw))
    if strans then eapi.editorsheet:draw((transdraw[1]+(strans-1))-24, transdraw[2]+(strans-1)*8,transdraw[3], 0, transdraw[6],transdraw[7]) end
  end

--Redraw the flag byte circles
  function se:redrawFLAG()
    local flags = string.byte(flagsData:sub(sprsid,sprsid))
    for i=1,8 do --Bit number
      if bit.band(bit.rshift(flags,8-i),1) == 1 then
        eapi.editorsheet:draw(125+i,flagsdraw[1]+(i-1)*7,flagsdraw[2]) --It's ON
      else
        eapi.editorsheet:draw(125,flagsdraw[1]+(i-1)*7,flagsdraw[2])--It's OFF
      end
    end
  end

--Redraw all the screen
  function se:_redraw()
    self:redrawCP()
    self:redrawSPR()
    self:redrawSPRS()
    self:redrawZSlider()
    self:redrawSSlider()
    self:redrawFLAG()
    self:redrawTOOLS()
  end

--Update some timers
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

--Mouse function of ImageDrawing
  function se:mouseImageDrawing(x,y,b,it,state)
    if state ~= "hover" then
      local cx, cy = whereInGrid(x,y,imggrid)
      if cx then
        if (not it) and state == "pressed" then mflag = true end
        tools[stool](self,cx,cy,b)
        self:redrawSPR() self:redrawSPRS()
      end
    end

    --Cursor
    if true then
      if whereInGrid(x,y,imggrid) and stool < 3 then
        if stool == 1 then
          if isKDown("lshift","rshift") or isMDown(2) then
            cursor("eraser")
          else
            cursor("pencil")
          end
        elseif stool == 2 then
          cursor("bucket")
        end
      else
        local cur = cursor()
        if cur == "pencil" or cur == "bucket" or cur == "eraser" then cursor("normal") end
      end
    end
  end

  function se:mouseSpriteSelection(x,y,b,it,state)
    local cx, cy = whereInGrid(x,y,sprsgrid)
    if cx then
      local cx, cy = math.min(cx-1,sprsgrid[5]-zscale), math.min(cy-1,sprsgrid[6]-zscale)
      sprsid = cy*sheetW+cx+1+(sprsbank*sheetW*bankH-sheetW*bankH)
      sprssrect[1] = cx*8 -1
      sprssrect[2] = sprsrecto[2]+cy*8
      imgquad:setViewport(cx*8,cy*8 + (sprsbank-1)*bsizeH,imgw*zscale,imgh*zscale)

      self:redrawSPRS() self:redrawSPR() self:redrawFLAG()
      if state == "pressed" then sprsmflag = true end
    end
  end

  function se:mouseZoomSlider(x,y,b,it,state)
    local cx, cy = whereInGrid(x,y,zgrid)
    if state == "pressed" then
      if cx then
        zflag = "down"
        zoom = cx; self:updateZoom()
        cursor("handpress")
        self:redrawSPRS() self:redrawSPR() self:redrawFLAG() self:redrawZSlider()
      end
    elseif state == "moved" then
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
    elseif state == "released" then
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
  end

  function se:mouseSizeSlider(x,y,b,it,state)
    local cx, cy = whereInGrid(x,y,sgrid)
    if state == "pressed" then
      if cx then
        sflag = "down"
        size = cx; self:updateZoom()
        cursor("handpress")
        self:redrawSPRS() self:redrawSPR() self:redrawFLAG() self:redrawSSlider()
      end
    elseif state == "moved" then
      if cx then
        if sflag == "down" then
          size = cx; self:updateZoom()
          self:redrawSPRS() self:redrawSPR() self:redrawFLAG() self:redrawSSlider()
        else
          sflag = "hover"
          cursor("handrelease")
        end
      elseif sflag == "hover" then
        cursor("normal")
        sflag = "none"
      end
    elseif state == "released" then
      if cx then
        if sflag == "down" then
          size = cx; self:updateZoom()
          sflag = "hover"
          cursor("handrelease")
          self:redrawSPRS() self:redrawSPR() self:redrawFLAG() self:redrawSSlider()
        else
          sflag = "hover"
          cursor("handrelease")
        end
      elseif sflag ~= "none" then
        cursor("normal")
        sflag = "none"
      end
    end
  end

  function se:mousepressed(x,y,b,it)
    if isKDown("lshift","rshift") or isMDown(2) then b = 2 end

    --Pallete Color Selection (Only in mousepressed)
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

    --Bank selection (Only in mousepressed)
    local cx = whereInGrid(x,y,sprsbanksgrid)
    if cx then
      sprsbank = cx
      local idbank = math.floor((sprsid-1)/(sheetW*bankH))+1
      if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*sheetW*bankH elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*sheetW*bankH end
      self:updateZoom() self:redrawSPRS() self:redrawSPR() self:redrawFLAG()
    end

    --Tool Selection (Only in mousepressed)
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

    --Transformation Selection (Only in mousepressed)
    local cx, cy = whereInGrid(x,y,transgrid)
    if cx and transformations[cx] then
      transform(cx)
    end

    --Setting Flags (Only in mousepressed)
    local cx, cy = whereInGrid(x,y,flagsgrid)
    if cx then
      cx = 9-cx
      local flags = string.byte(flagsData:sub(sprsid))
      flags = bit.bxor(flags,bit.lshift(1,cx-1))
      flagsData = flagsData:sub(0,sprsid-1)..string.char(flags)..flagsData:sub(sprsid+1,-1)
      self:redrawFLAG()
    end

    --Zoom Slider
    self:mouseZoomSlider(x,y,b,it,"pressed")

    --Size Slider
    self:mouseSizeSlider(x,y,b,it,"pressed")

    --Sprite Selection
    self:mouseSpriteSelection(x,y,b,it,"pressed")

    --Image Drawing
    self:mouseImageDrawing(x,y,b,it,"pressed")
  end

  function se:mousemoved(x,y,dx,dy,it)
    local b = 1; if isKDown("lshift","rshift") or isMDown(2) then b = 2 end

    --Image Drawing
    if (not it and mflag) or it then
      self:mouseImageDrawing(x,y,b,it,"moved")
    else --For the cursor to update
      self:mouseImageDrawing(x,y,b,it,"hover")
    end

    --Sprite Selection
    if (not it and sprsmflag) or it then
      self:mouseSpriteSelection(x,y,b,it,"moved")
    end

    --Zoom Slider
    self:mouseZoomSlider(x,y,b,it,"moved")

    --Size Slider
    self:mouseSizeSlider(x,y,b,it,"moved")
  end

  function se:mousereleased(x,y,b,it)
    if isKDown("lshift","rshift") then b = 2 end

    --Image Drawing
    if (not it and mflag) or it then
      self:mouseImageDrawing(x,y,b,it,"released")
    end
    mflag = false

    --Sprite Selection
    if (not it and sprsmflag) or it then
      self:mouseSpriteSelection(x,y,b,it,"released")
    end
    sprsmflag = false

    --Zoom Slider
    self:mouseZoomSlider(x,y,b,it,"released")

    --Size Slider
    self:mouseSizeSlider(x,y,b,it,"released")
  end

  function se:keypressed(key,sc)
    --Palette Switching
    if sc == "q" or sc == "e" then
      if isKDown("lshift","rshift") then
        if sc == "e" then
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
        if sc == "e" then
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
    elseif sc == "w" or sc == "a" or sc == "s" or sc == "d" then
      local function setBank(bank)
        local idbank = math.floor((sprsid-1)/(sheetW*bankH))+1
        sprsbank = bank
        if idbank > sprsbank then
          sprsid = sprsid-(idbank-sprsbank)*sheetW*bankH
        elseif sprsbank > idbank then
          sprsid = sprsid+(sprsbank-idbank)*sheetW*bankH
        end
      end

      --Update the selection box position
      local cx, cy = (sprssrect[1]+1)/8, (sprssrect[2]-sprsrecto[2])/8
      if sc == "a" then --Left
        cx = cx - zscale
      elseif sc == "d" then --Right
        cx = cx + zscale
      elseif sc == "w" then --Up
        cy = cy - zscale
      elseif sc == "s" then --Down
        cy = cy + zscale
      end
      if cx < 0 then cx, cy = ((cy == 0 and sprsbank == 1) and 0 or sheetW-1), cy-zscale elseif cx >= sheetW then cx, cy = ((cy == bankH-zscale and sprsbank == 4) and sheetW-1 or 0), cy+zscale end
      if cy < 0 then
        if sprsbank > 1 then
          setBank(sprsbank-1)
          cy = bankH-1
        else
          cy = 0
        end
      elseif cy > bankH-1 then
        if sprsbank < 4 then
          setBank(sprsbank+1)
          cy = 0
        else
          cy = bankH-1
        end
      end

      cx, cy = math.min(cx,sprsgrid[5]-zscale), math.min(cy,sprsgrid[6]-zscale)
      sprsid = cy*sheetW+cx+1+(sprsbank*sheetW*bankH-sheetW*bankH)
      sprssrect[1] = cx*8-1
      sprssrect[2] = sprsrecto[2]+cy*8
      imgquad:setViewport(cx*8,cy*8 + (sprsbank-1)*bsizeH,imgw*zscale,imgh*zscale)
      self:redrawSPRS() self:redrawSPR()
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
    --Transformations
    ["r"] = function() transform(1) end,
    ["shift-r"] = function() transform(2) end,
    ["f"] = function() transform(3) end,
    ["shift-f"] = function() transform(4) end,
    ["i"] = function() transform(5) end
  }

  return se