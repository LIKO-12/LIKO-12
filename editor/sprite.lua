local s = {}

local basexx = require("libraries.basexx")

local img, mflag
local imgw, imgh = 8, 8 --Image Width, Image Height
local psize = 10 --Zoomed Pixel Size
local imgdraw = {3+1,8+3+1,0,psize,psize} --Image Location
local imgrecto = {3,3+8,psize*imgw+2,psize*imgh+2,1}
local imggrid = {3+1,8+3+1,psize*imgw,psize*imgh,imgw,imgh}

local sprsrecto = {1,128-(8+24+1),192,24+2, 1} --SpriteSheet Outline Rect
local sprsdraw = {1,128-(8+24)} --SpriteSheet Draw Location
local sprsgrid = {1,128-(8+24),192,8*3,24,3}
local sprssrect = {0,128-(8+24+1),8+2,8+2,8} --SpriteSheet Select Rect
local sprsidrect = {192-(36+13),128-(8+24+9),13,7,7,14}
local sprsbanksY = 128 - (8+24+9)
local sprsbanksgrid = {192-32,sprsbanksY+1,8*4,8,4,1}
local sprsid = 1 --SpriteSheet Selected ID
local sprsmflag = false
local sprsbquads = {} --SpriteSheets 4 BanksQuads
local sprsbank = 1 --Current Selected Bank
for i = 1, 4 do
  sprsbquads[i] = api.SpriteMap:image():quad(1,(i*8*3-8*3)+1,_,3*8)
end

local temp = 0
local palpsize = 13
local palimg = api.Image(api.ImageData(4,4):map(function() temp = temp + 1 return temp end ))
local palrecto = {192-(palpsize*4+3),8+3,palpsize*4+2,palpsize*4+2,1}
local paldraw = {192-(palpsize*4+2),8+3+1,0,palpsize,palpsize}
local palgrid = {192-(palpsize*4+2),8+3+1,palpsize*4,palpsize*4,4,4}

local colsrectL = {192-(palpsize*4+3),8+3,palpsize+2,palpsize+2,8}
local colsrectR = {192-(palpsize*4+2),8+3+1,palpsize,palpsize,1}
local colsL = 0 --Color Select Left
local colsR = 0 --Color Select Right

local toolsdraw = {104, 192-102,sprsbanksY-2, 5,1, 1,1, api.EditorSheet} --Tools Draw Config
local toolsgrid = {toolsdraw[2],toolsdraw[3], toolsdraw[4]*8,toolsdraw[5]*8, toolsdraw[4],toolsdraw[5]} --Tools Selection Grid
local stool = 1

local tbtimer = 0
local tbtime = 0.1125
local tbflag = false

local transdraw = {109, 192-105,sprsbanksY-15, 5,1, 1,1, api.EditorSheet} --Transformations Draw Config
local transgrid = {transdraw[2],transdraw[3], transdraw[4]*8, transdraw[5]*8, transdraw[4], transdraw[5]} --Transformations Selection Grid
local strans --Selected Transformation

local transtimer
local transtime = 0.1125

local copyPaste_Time = 0 --Text delay time before it vanishes
local copyOn = 0 --If user want to copy
local pasteOn = 0 --If user want to paste 

local toolshold = {true,true,false,false,false} --Is it a button (Clone, Stamp, Delete) or a tool (Pencil, fill)
local tools = {
  function(self,cx,cy,b) --Pencil (Default)
    local data = api.SpriteMap:data()
    local qx,qy = api.SpriteMap:rect(sprsid)
    local col = (b == 1 or api.isMDown(1)) and colsL or colsR
    data:setPixel(qx+cx-1,qy+cy-1,col)
    api.SpriteMap.img = data:image()
  end,

  function(self,cx,cy,b) --Fill (Bucket)
    local data = api.SpriteMap:data()
    local qx,qy = api.SpriteMap:rect(sprsid)
    local col = (b == 1 or api.isMDown(1)) and colsL or colsR
    local tofill = data:getPixel(qx+cx-1,qy+cy-1)
    if tofill == col then return end
    local function spixel(x,y) if x >= qx and x <= qx+7 and y >= qy and y <= qy+7 then data:setPixel(x,y,col) end end
    local function gpixel(x,y) if x >= qx and x <= qx+7 and y >= qy and y <= qy+7 then return data:getPixel(x,y) else return false end end
    local function mapPixel(x,y)
      if gpixel(x,y) and gpixel(x,y) == tofill then spixel(x,y) end
      if gpixel(x+1,y) and gpixel(x+1,y) == tofill then mapPixel(x+1,y) end
      if gpixel(x-1,y) and gpixel(x-1,y) == tofill then mapPixel(x-1,y) end
      if gpixel(x,y+1) and gpixel(x,y+1) == tofill then mapPixel(x,y+1) end
      if gpixel(x,y-1) and gpixel(x,y-1) == tofill then mapPixel(x,y-1) end
    end
    mapPixel(qx+cx-1,qy+cy-1)
    api.SpriteMap.img = data:image()
  end,

  function(self) --Clone (Copy)
    self:copy()
  end,

  function(self) --Stamp (Paste)
    self:paste()
  end,

  function(self) --Delete (Erase)
    local data = api.SpriteMap:data()
    local qx,qy = api.SpriteMap:rect(sprsid)
    for px = 0, 7 do for py = 0, 7 do
      data:setPixel(qx+px,qy+py,0)
    end end
    api.SpriteMap.img = data:image()
  end
}

local function transform(tfunc)
  local current = api.SpriteMap:extract(sprsid)
  local new = api.ImageData(current:width(),current:height())
  current:map(function(x,y,c)
    local nx,ny,nc = tfunc(x,y,c,current:width(),current:height())
    new:setPixel(nx or x,ny or y,nc or c)
  end)
  local x,y = api.SpriteMap:rect(sprsid)
  local data = api.SpriteMap:data()
  data:paste(new,x,y)
  api.SpriteMap.img = data:image()
end

local transformations = {
  function(x,y,c,w,h) return h+1-y,x end, --Rotate right
  function(x,y,c,w,h) return y, w+1-x end, --Rotate left
  function(x,y,c,w,h) return w+1-x,y end, --Flip horizental
  function(x,y,c,w,h) return x,h+1-y end, --Flip vertical
  function(x,y,c,w,h) return w+1-x,h+1-y end --Flip horizentaly + verticaly
}

function s:_switch()
  img = api.ImageData(imgw,imgh):map(function() return 0 end)
  mflag = false
end

function s:export(path)
  local FileData = api.SpriteMap:data():export(path)
  if not path then
    return basexx.to_base64(FileData:getString())
  end
end

function s:copy()
  api.setclip(basexx.to_base64(api.SpriteMap:extract(sprsid):export():getString()))
  copyOn = 1 
  copyPaste_Time = 0
  api.rect(1,128-7,192,8,10) --Avoids redrawing every tick
end

function s:copyPaste_Text(dt)
	if copyOn == 1 and copyPaste_Time < 2 then
		api.color(5)
		api.print("COPIED 1 X 1 SPRITES",2,128-5)  
		copyPaste_Time = copyPaste_Time + dt
	elseif copyPaste_Time >= 2 then
			api.rect(1,128-7,192,8,10)
			elseif pasteOn == 1 then
				api.rect(1,128-7,192,8,10)
				if copyPaste_Time < 2 then
					api.color(5)
					api.print("PASTED 1 X 1 SPRITES",2,128-5)
					copyPaste_Time = copyPaste_Time + dt
				end
	end
end

function s:paste()
  local ok, err = pcall(function()
    local imd = api.ImageData(api.getclip() or "")
    local dx,dy,dw,dh = api.SpriteMap:rect(sprsid)
    local sheetdata = api.SpriteMap:data()
    sheetdata:paste(imd,dx,dy,1,1,dw,dh)
    api.SpriteMap.img = sheetdata:image()
    self:_redraw()
  end)
  pasteOn = 1  
  copyOn = 0
  copyPaste_Time = 0	
end

function s:load(path)
  if path then
    api.SpriteMap = api.SpriteSheet(api.Image("/"..path..".png"),24,12)
  else
    api.SpriteMap = api.SpriteSheet(api.ImageData(24*8,12*8):image(),24,12)
  end
end

function s:redrawCP() --Redraw color pallete
  api.rect_line(unpack(palrecto))
  palimg:draw(unpack(paldraw))
  api.rect_line(unpack(colsrectR))
  api.rect_line(unpack(colsrectL))
end

function s:redrawSPRS()
  api.rect(unpack(sprsrecto))
  api.SpriteMap:image():draw(sprsdraw[1],sprsdraw[2],sprsdraw[3],sprsdraw[4],sprsdraw[5],sprsbquads[sprsbank])
  api.rect_line(unpack(sprssrect))
  api.rect(unpack(sprsidrect))
  api.color(sprsidrect[6])
  local id = sprsid if id < 10 then id = "00"..id elseif id < 100 then id = "0"..id end
  api.print(id,sprsidrect[1]+1,sprsidrect[2]+1)
  api.SpriteGroup(97,192-32,sprsbanksY,4,1,1,1,api.EditorSheet)
  api.EditorSheet:draw(sprsbank+72,192-(40-sprsbank*8),sprsbanksY)
end

function s:redrawSPR()
  api.rect(unpack(imgrecto))
  api.SpriteMap:image():draw(imgdraw[1],imgdraw[2],imgdraw[3],imgdraw[4],imgdraw[5],api.SpriteMap:quad(sprsid))
  api.rect(sprsidrect[1]-9,sprsidrect[2]-1,8,8,1)
  api.SpriteMap:image():draw(sprsidrect[1]-9,sprsidrect[2]-1,0,1,1,api.SpriteMap:quad(sprsid))
end

function s:redrawTOOLS()
  --Tools
  api.SpriteGroup(unpack(toolsdraw))
  api.Sprite((toolsdraw[1]+(stool-1))-24,toolsdraw[2]+(stool-1)*8,toolsdraw[3],0,toolsdraw[6],toolsdraw[7],api.EditorSheet)
  
  --Transformations
  api.SpriteGroup(unpack(transdraw))
  if strans then api.Sprite((transdraw[1]+(strans-1))-24,transdraw[2]+(strans-1)*8,transdraw[3],0,transdraw[6],transdraw[7],api.EditorSheet) end
end

function s:redrawFLAG()
  api.SpriteGroup(126,192-64,sprsbanksY-18,8,1,1,1,api.EditorSheet)
  api.SpriteGroup(126,192-64,sprsbanksY-10,8,1,1,1,api.EditorSheet)
end

function s:_redraw()
  self:redrawCP()
  self:redrawSPR()
  self:redrawSPRS()
  self:redrawFLAG()
  self:redrawTOOLS()
end

function s:_update(dt)
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
  s:copyPaste_Text(dt) 
end

function s:_mpress(x,y,b,it)
  --if api.isInRect(x,y,{1,1,192,8}) then api.SpriteMap:data():export("editorsheet") end
  --Pallete Color Selection
  local cx, cy = api.whereInGrid(x,y,palgrid)
  if cx then
    if b == 1 then
      colsL = (cy-1)*4+cx if colsL == 1 then colsL = 0 end
      local cx, cy = cx-1, cy-1
      colsrectL[1] = 192-(palpsize*4+3)+palpsize*cx
      colsrectL[2] = 8+3+palpsize*cy
    elseif b == 2 then
      colsR = (cy-1)*4+cx if colsR == 1 then colsR = 0 end
      local cx, cy = cx-1, cy-1
      colsrectR[1] = 192-(palpsize*4+2)+palpsize*cx
      colsrectR[2] = 8+3+1+palpsize*cy
    end
    
    self:redrawCP()
  end
  
  --Bank selection
  local cx = api.whereInGrid(x,y,sprsbanksgrid)
  if cx then
    sprsbank = cx
    local idbank = api.floor((sprsid-1)/(24*3))+1
    if idbank > sprsbank then sprsid = sprsid-(idbank-sprsbank)*24*3 elseif sprsbank > idbank then sprsid = sprsid+(sprsbank-idbank)*24*3 end
    self:redrawSPRS() self:redrawSPR()
  end
  
  --Sprite Selection
  local cx, cy = api.whereInGrid(x,y,sprsgrid)
  if cx then
    sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
    local cx, cy = cx-1, cy-1
    sprssrect[1] = cx*8
    sprssrect[2] = 128-(8+24+1)+cy*8
    
    self:redrawSPRS() self:redrawSPR() sprsmflag = true
  end
  
  --Tool Selection
  local cx, cy = api.whereInGrid(x,y,toolsgrid)
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
  local cx, cy = api.whereInGrid(x,y,transgrid)
  if cx and transformations[cx] then
    transform(transformations[cx]) transtimer, strans = 0, cx
    self:redrawSPRS() self:redrawSPR() self:redrawTOOLS()
  end
  
  --Image Drawing
  local cx, cy = api.whereInGrid(x,y,imggrid)
  if cx then
    if not it then mflag = true end
    tools[stool](self,cx,cy,b)
    self:redrawSPR() self:redrawSPRS()
  end
end

function s:_mmove(x,y,dx,dy,it,iw)
  if iw then return end
  
  --Image Drawing
  if (not it and mflag) or it then
    local cx, cy = api.whereInGrid(x,y,imggrid)
    if cx then
      tools[stool](self,cx,cy)
      self:redrawSPR() self:redrawSPRS()
    end
  end
  
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = api.whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = 128-(8+24+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR()
    end
  end
end

function s:_mrelease(x,y,b,it)

  --Image Drawing
  if (not it and mflag) or it then
    local cx, cy = api.whereInGrid(x,y,imggrid)
    if cx then
      tools[stool](self,cx,cy,b)
      self:redrawSPR() self:redrawSPRS()
    end
  end
  mflag = false
  
  --Sprite Selection
  if (not it and sprsmflag) or it then
    local cx, cy = api.whereInGrid(x,y,sprsgrid)
    if cx then
      sprsid = (cy-1)*24+cx+(sprsbank*24*3-24*3)
      local cx, cy = cx-1, cy-1
      sprssrect[1] = cx*8
      sprssrect[2] = 128-(8+24+1)+cy*8
      
      self:redrawSPRS() self:redrawSPR()
    end
  end
  sprsmflag = false
end

local bank = function(bank)
  return function()
    local idbank = api.floor((sprsid-1)/(24*3))+1
    sprsbank = bank
    if idbank > sprsbank then
      sprsid = sprsid-(idbank-sprsbank)*24*3
    elseif sprsbank > idbank then
      sprsid = sprsid+(sprsbank-idbank)*24*3
    end
    s:redrawSPRS() s:redrawSPR()
  end
end

s.keymap = {
  ["ctrl-c"] = s.copy,
  ["ctrl-v"] = s.paste,
  ["1"] = bank(1), ["2"] = bank(2), ["3"] = bank(3), ["4"] = bank(4),
  ["z"] = function() stool=1 s:redrawTOOLS() end,
  ["x"] = function() stool=2 s:redrawTOOLS() end,
  ["delete"] = function() tools[5](s) s:redrawSPRS() s:redrawSPR() end,
}

return s
