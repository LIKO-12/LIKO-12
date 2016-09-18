class = require("class")
require("offsets")
--Cursors--
if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
love.mouse.newCursor = function() end
love.mouse.setCursor = function() end
end

--[[function SetCursor(name)
  love.mouse.setCursor(_Cursors[name or ""] or _Cursors["normal"])
end]]

--Internal Variables--
_Font = love.graphics.newImageFont("/font.png",'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"\'`-_/1234567890!?[](){}.,;:<>+=%#^*~ ',1)
--love.graphics.newFont("font.ttf",20)

_ShouldDraw = false
_ForceDraw = false

_ScreenTitle = "Liko 12"

_ColorSet = { --Pico8 Colorset, Should add other 16 color because it's double the width of pico8
  {0,0,0,255}, --Black 1
  {28,43,83,255}, --Dark Blue 2
  {127,36,84,255}, --Dark Red 3
  {0,135,81,255}, --Dark Green 4
  {171,82,54,255}, --Brown 5
  {96,88,79,255}, --Dark Gray 6
  {195,195,198,255}, --Gray 7
  {255,241,233,255}, --White 8
  {237,27,81,255}, --Red 9
  {250,162,27,255}, --Orange 10
  {247,236,47,255}, --Yellow 11
  {93,187,77,255}, --Green 12
  {81,166,220,255}, --Blue 13
  {131,118,156,255}, --Purple 14
  {241,118,166,255}, --Pink 15
  {252,204,171,255} --Human Skin 16
}
_ColorSet[0] = {0,0,0,0}

--Callbacks--
function _startup() end --Called at the start of the program
function _update(dt) end --Called when the program updates

function _mpress(x,y,button,it) end --Called when a mouse button is pressed
function _mmove(x,y,dx,dy,it,iw) end --Called when the mouse moves
function _mrelease(x,y,button,it) end --Called when a mouse button is released

function _tpress(id,x,y,button,pressure) end --Called when the screen is touched
function _tmove(id,x,y,pressure) end --Called when the screen touch moves
function _trelease(id,x,y,pressure) end --Called when the screen touch releases

function _kpress(key,scancode,isrepeat) end --Called when a key is pressed
function _krelease(key,scancode) end --Called when a key is released
function _tinput(text) end --Called when text input, uses utf8 format

--Autorun Callbacks--
function _auto_startup() _startup() end --Called at the start of the program
function _auto_update(dt) _update(dt) end --Called when the program updates

function _auto_mpress(x,y,button,it) _mpress(x,y,button,it) end --Called when a mouse button is pressed
function _auto_mmove(x,y,dx,dy,it) _mmove(x,y,dx,dy,it) end --Called when the mouse moves
function _auto_mrelease(x,y,button,it) _mrelease(x,y,button,it) end --Called when a mouse button is released

function _auto_tpress(id,x,y,button,pressure) _tpress(id,x,y,button,pressure) end --Called when the screen is touched
function _auto_tmove(id,x,y,pressure) _tmove(id,x,y,pressure) end --Called when the screen touch moves
function _auto_trelease(id,x,y,pressure) _trelease(id,x,y,pressure) end --Called when the screen touch releases

function _auto_kpress(key,scancode,isrepeat) _kpress(key,scancode,isrepeat) end --Called when a key is pressed
function _auto_krelease(key,scancode) _krelease(key,scancode) end --Called when a key is released
function _auto_tinput(text) _tinput(text) end --Called when text input, uses utf8 format

--Internal Funtions--
function _ScreenToLiko(x,y)
  x, y = x-_ScreenX, y-_ScreenY
  return floor(x/_ScreenScaleX)+1, floor(y/_ScreenScaleY)+1
end

function _GetColor(c) return _ColorSet[c or 1] end
function _GetColorID(r,g,b,a)
  for id,col in pairs(_ColorSet) do
    if col[1] == r and col[2] == g and col[3] == b and col[4] == (a or 255) then
      return id
    end
  end
  return false
end

--API Functions--
--Graphics Section--
function clear(c) --Clears the screen (fills it with a specific color)
  color(c or 1)
  rect(1,1,192,128)
  _ShouldDraw = true
end

function color(id)
  love.graphics.setColor(_ColorSet[id or 1] or _ColorSet[1])
end

function stroke(width) --Sets the lines and the points width
  love.graphics.setPointSize(width or 1)
  love.graphics.setLineWidth(width or 1)
end

function points(...) --Draws the points: x1,y1, x2, y2, ...
  local args = {...}
  if not (#args % 2 == 0) then color(args[#args]) table.remove(args,#args) end
  for k,v in ipairs(args) do if (k % 2 == 0) then args[k] = v + _goffset.pointY else args[k] = v + _goffset.pointX end end
  love.graphics.points(unpack(args))
  _ShouldDraw = true
end
point = points

function line(...)
  local args = {...}
  if not (#args % 2 == 0) then color(args[#args]) table.remove(args,#args) end
  love.graphics.line(unpack(args))
  _ShouldDraw = true
end

function circle(x,y,r,s,c) --x,y,radius,segments,color
  if c then color(c) end
  love.graphics.circle("fill",x,y,r,s)
  _ShouldDraw = true
end

function circle_line(x,y,r,s,c) --x,y,radius,segments,color
  if c then color(c) end
  love.graphics.circle("line",x,y,r,s)
  _ShouldDraw = true
end

function rect(x,y,w,h,c)
  if c then color(c) end
  local x,y = x + _goffset.rectX, y + _goffset.rectY
  love.graphics.rectangle("fill",x,y,w,h)
  _ShouldDraw = true
end

function rect_line(x,y,w,h,c)
  if c then color(c) end
  local x,y = x + _goffset.rect_lineX, y + _goffset.rect_lineY
  local w, h = w + _goffset.rect_lineW, h + _goffset.rect_lineH
  love.graphics.rectangle("line",x,y,w,h)
  --love.graphics.line(x,y,x+w,y,x+w,y+h,x,y+h,x,y)
  _ShouldDraw = true
end

cprint = print --Console Print

function print(text,lx,ly)
  love.graphics.print(text, floor((lx or 1)+_goffset.printX), floor((ly or 1)+_goffset.printY)) _ShouldDraw = true --_goffset.rectX
end

function print_grid(text,lx,ly)
  love.graphics.print(text, floor(((lx or 1)*8-6)+_goffset.printX), floor(((ly or 1)*8-6)+_goffset.printY)) _ShouldDraw = true
end

--Image Section--
Image = class("Liko12.image")
function Image:initialize(path) if type(path) == "string" then self.image = love.graphics.newImage(path) else self.image = love.graphics.newImage(path.imageData) end end
function Image:draw(x,y,r,sx,sy,quad) love.graphics.setColor(255,255,255,255) if quad then love.graphics.draw(self.image,quad,x+_goffset.quadX,y+_goffset.quadY,r,sx,sy) else love.graphics.draw(self.image,x+_goffset.imageX,y+_goffset.imageY,r,sx,sy) end _ShouldDraw = true return self end
function Image:size() return self.image:getDimensions() end
function Image:width() return self.image:getWidth() end
function Image:height() return self.image:getHeight() end
function Image:data() return ImageData(self.image:getData()) end
function Image:quad(x,y,w,h) return love.graphics.newQuad(x-1,y-1,w or self:width(),h or self:height(),self:width(),self:height()) end

ImageData = class("Liko12.imageData")
function ImageData:initialize(w,h) if h then self.imageData = love.image.newImageData(w or 192, h or 128) elseif type(w) == "string" then self.imageData = love.image.newImageData(love.filesystem.newFileData(w,"spritemap","base64")) else self.imageData = w end end
function ImageData:size() return self.imageData:getDimensions() end
function ImageData:getPixel(x,y) return self.imageData:getPixel((x or 1)-1,(y or 1)-1) end
function ImageData:setPixel(x,y,c) self.imageData:setPixel((x or 1)-1,(y or 1)-1,unpack(_GetColor(c))) return self end
function ImageData:map(mf)
  self.imageData:mapPixel(
    function(x,y,r,g,b,a)
      local newCol = mf(x+1,y+1,_GetColorID(r,g,b,a))
      newCol = newCol and _GetColor(newCol) or {r,g,b,a}
      return unpack(newCol)
    end)
  return self
end
function ImageData:height() return self.imageData:getHeight() end
function ImageData:width() return self.imageData:getWidth() end
function ImageData:paste(sprData,dx,dy,sx,sy,sw,sh) self.imageData:paste(sprData.imageData,(dx or 1)-1,(dy or 1)-1,(sx or 1)-1,(sy or 1)-1,sw or sprData:width(), sh or sprData:height()) return self end
function ImageData:quad(x,y,w,h) return love.graphics.newQuad(x-1,y-1,w or self:width(),h or self:height(),self:width(),self:height()) end
function ImageData:image() return Image(self) end
function ImageData:export(filename) return self.imageData:encode("png",filename and (filename..".png") or nil) end
function ImageData:enlarge(scale)
  local scale = floor(scale or 1)
  if scale <= 0 then scale = 1 end --Protection
  if scale == 1 then return self end
  local newData = ImageData(self:width()*scale,self:height()*scale)
  self:map(function(x,y,c)
    for iy=1, scale do for ix=1, scale do
      newData:setPixel((x-1)*scale + ix,(y-1)*scale + iy,c)
    end end
  end)
  return newData
end

SpriteSheet = class("Liko12.spriteSheet")
function SpriteSheet:initialize(img,w,h)
  self.img, self.w, self.h = img, w, h
  self.cw, self.ch, self.quads = self.img:width()/self.w, self.img:height()/self.h, {}
  for y=1,self.h do for x=1,self.w do
    table.insert(self.quads,self.img:quad(x*self.cw-(self.cw-1),y*self.ch-(self.ch-1),self.cw,self.ch))
  end end
end
function SpriteSheet:image() return self.img end
function SpriteSheet:data() return self.img:data() end
function SpriteSheet:quad(id) return self.quads[id] end
function SpriteSheet:rect(id) local x,y,w,h = self.quads[id]:getViewport() return x+1,y+1,w,h end
function SpriteSheet:draw(id,x,y,r,sx,sy) self.img:draw(x,y,r,sx,sy,self.quads[id]) _ShouldDraw = true return self end
function SpriteSheet:extract(id) return ImageData(8,8):paste(self:data(),1,1,self:rect(id)) end

function Sprite(id,x,y,r,sx,sy,sheet) (sheet or SpriteMap):draw(id,x,y,r,sx,sy) end
function SpriteGroup(id,x,y,w,h,sx,sy,sheet)
  local sx,sy = floor(sx or 1), floor(sy or 1)
  for spry = 1, h or 1 do for sprx = 1, w or 1 do
    (sheet or SpriteMap):draw((id-1)+sprx+(spry*24-24),x+(sprx*sx*8-sx*8),y+(spry*sy*8-sy*8),0,sx,sy)
  end end
end

EditorSheet = SpriteSheet(Image("/editorsheet.png"),24,12)

--Cursor Section--
_CurrentCursor = "normal"
_Cursors = {}
_CachedCursors = {}

function newCursor(data,name,hotx,hoty)
  _Cursors[name] = {data = data, hotx = hotx or 1, hoty = hoty or 1}
  _CachedCursors[name or "custom"] = love.mouse.newCursor(_Cursors[name].data:enlarge(_ScreenScale).imageData,(_Cursors[name].hotx-1)*_ScreenScale,(_Cursors[name].hoty-1)*_ScreenScale)
end

function loadDefaultCursors()
  newCursor(EditorSheet:extract(1),"normal",2,2)
  newCursor(EditorSheet:extract(2),"handrelease",3,2)
  newCursor(EditorSheet:extract(3),"handpress",3,4)
  newCursor(EditorSheet:extract(4),"hand",5,5)
  newCursor(EditorSheet:extract(5),"cross",4,4)
  setCursor(_CurrentCursor)
end

function setCursor(name)
 if not _CachedCursors[name] then _CachedCursors[name or "custom"] = love.mouse.newCursor(_Cursors[name].data:enlarge(_ScreenScale).imageData,(_Cursors[name].hotx-1)*_ScreenScale,(_Cursors[name].hoty-1)*_ScreenScale) end
 love.mouse.setCursor(_CachedCursors[name]) _CurrentCursor = name or "custom"
end

function clearCursorsCache() _CachedCursors = {} setCursor(_CurrentCursor) end

--Math Section--
ostime = os.time

function rand_seed(newSeed)
  love.math.setRandomSeed(newSeed)
end

function rand(minV,maxV) return love.math.random(minV,maxV) end

function floor(num) return math.floor(num) end

--Gui Function--
function isInRect(x,y,rect)
  if x >= rect[1] and y >= rect[2] and x <= rect[1]+rect[3] and y <= rect[2]+rect[4] then return true end return false
end

function whereInGrid(x,y, grid) --Grid X, Grid Y, Grid Width, Grid Height, NumOfCells in width, NumOfCells in height
  local gx,gy,gw,gh,cw,ch = unpack(grid)
  if isInRect(x,y,{gx,gy,gw,gh}) then
    local clw, clh = floor(gw/cw), floor(gh/ch)
    local x, y = x-gx, y-gy
    local hx = floor(x/clw)+1 hx = hx <= cw and hx or hx-1
    local hy = floor(y/clh)+1 hy = hy <= ch and hy or hy-1
    return hx,hy
  end
  return false, false
end

--FileSystem Function--
FS = {}
function FS.write(path,data)
  return love.filesystem.write(path,data)
end

function FS.read(path) return love.filesystem.read(path) end

--Misc Functions--
function keyrepeat(state) love.keyboard.setKeyRepeat(state) end
function showkeyboard(state) love.keyboard.setTextInput(state) end

--Spritesheet--
SpriteMap = SpriteSheet(ImageData(24*8,12*8):image(),24,12)
--[[_ImageSheet = {
IMG = ImageData(24*8,12*8)
}]]