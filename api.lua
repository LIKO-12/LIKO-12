_Class = require("class")
require("offsets")

_LK12VER = "V0.0.4 DEV"
_LK12VERC = 9--9 DEV, 10 PRE

_GIFSCALE = 2
_REBOOT = false

--Mobiles Cursor FIX--
if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
love.mouse.newCursor = function() end
love.mouse.setCursor = function() end
_IsMobile = true
end

--Internal Variables--
_FontChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"\'`-_/1234567890!?[](){}.,;:<>+=%#^*~ '
_Font = love.graphics.newImageFont("/font.png",_FontChars,1)
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

--Internal Funtions--
  function _ScreenToLiko(x,y)
    x, y = x-_ScreenX, y-_ScreenY
    return api.floor(x/_ScreenScaleX)+1, api.floor(y/_ScreenScaleY)+1
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

local function newAPI(noFS,sprsheetmap,carttilemap)
  local api = {}

  --Callbacks--
  function api._init() end --Called at the start of the program
  function api._update(dt) end --Called when the program updates

  function api._mpress(x,y,button,it) end --Called when a mouse button is pressed
  function api._mmove(x,y,dx,dy,it,iw) end --Called when the mouse moves
  function api._mrelease(x,y,button,it) end --Called when a mouse button is released

  function api._tpress(id,x,y,dx,dy,button,pressure) end --Called when the screen is touched
  function api._tmove(id,x,y,dx,dy,pressure) end --Called when the screen touch moves
  function api._trelease(id,x,y,dx,dy,pressure) end --Called when the screen touch releases

  function api._kpress(key,scancode,isrepeat) end --Called when a key is pressed
  function api._krelease(key,scancode) end --Called when a key is released
  function api._tinput(text) end --Called when text input, uses utf8 format

  --API Functions--
  --Graphics Section--
  function api.clear(c) --Clears the screen (fills it with a specific color)
    api.color(c or 1)
    api.rect(1,1,192,128)
    _ShouldDraw = true
  end

  function api.color(id)
    love.graphics.setColor(_ColorSet[id or 1] or _ColorSet[1])
  end

  function api.stroke(width) --Sets the lines and the points width
    love.graphics.setPointSize(width or 1)
    love.graphics.setLineWidth(width or 1)
  end

  function api.points(...) --Draws the points: x1,y1, x2, y2, ...
    local args = {...}
    if not (#args % 2 == 0) then api.color(args[#args]) table.remove(args,#args) end
    for k,v in ipairs(args) do if (k % 2 == 0) then args[k] = v + _goffset.pointY else args[k] = v + _goffset.pointX end end
    love.graphics.points(unpack(args))
    _ShouldDraw = true
  end
  api.point = api.points

  function api.line(...)
    local args = {...}
    if not (#args % 2 == 0) then api.color(args[#args]) table.remove(args,#args) end
    love.graphics.line(unpack(args))
    _ShouldDraw = true
  end

  api.lines = api.line

  function api.circle(x,y,r,s,c) --x,y,radius,segments,color
    if c then api.color(c) end
    love.graphics.circle("fill",x,y,r,s)
    _ShouldDraw = true
  end

  function api.circle_line(x,y,r,s,c) --x,y,radius,segments,color
    if c then api.color(c) end
    love.graphics.circle("line",x,y,r,s)
    _ShouldDraw = true
  end

  function api.rect(x,y,w,h,c)
    if c then api.color(c) end
    local x,y = x + _goffset.rectX, y + _goffset.rectY
    love.graphics.rectangle("fill",x,y,w,h)
    _ShouldDraw = true
  end

  function api.rect_line(x,y,w,h,c)
    if c then api.color(c) end
    local x,y = x + _goffset.rect_lineX, y + _goffset.rect_lineY
    local w, h = w + _goffset.rect_lineW, h + _goffset.rect_lineH
    love.graphics.rectangle("line",x,y,w,h)
    _ShouldDraw = true
  end

  function api.print(text,lx,ly)
    love.graphics.print(text, api.floor((lx or 1)+_goffset.printX), api.floor((ly or 1)+_goffset.printY)) _ShouldDraw = true --_goffset.rectX
  end

  function api.print_grid(text,lx,ly)
    love.graphics.print(text, api.floor(((lx or 1)*8-6)+_goffset.printX), api.floor(((ly or 1)*8-6)+_goffset.printY)) _ShouldDraw = true
  end

  --Image Section--
  api.Image = _Class("Liko12.image")
  function api.Image:initialize(path) if type(path) == "string" then self.image = love.graphics.newImage(path) else self.image = love.graphics.newImage(path.imageData) end end
  function api.Image:draw(x,y,r,sx,sy,quad) love.graphics.setColor(255,255,255,255) if quad then love.graphics.draw(self.image,quad,x+_goffset.quadX,y+_goffset.quadY,r,sx,sy) else love.graphics.draw(self.image,x+_goffset.imageX,y+_goffset.imageY,r,sx,sy) end api.color(8) _ShouldDraw = true return self end
  function api.Image:size() return self.image:getDimensions() end
  function api.Image:width() return self.image:getWidth() end
  function api.Image:height() return self.image:getHeight() end
  function api.Image:data() return api.ImageData(self.image:getData()) end
  function api.Image:quad(x,y,w,h) return love.graphics.newQuad(x-1,y-1,w or self:width(),h or self:height(),self:width(),self:height()) end

  api.ImageData = _Class("Liko12.imageData")
  function api.ImageData:initialize(w,h) if h then self.imageData = love.image.newImageData(w or 192, h or 128) elseif type(w) == "string" then self.imageData = love.image.newImageData(love.filesystem.newFileData(w,"spritemap","base64")) else self.imageData = w end end
  function api.ImageData:size() return self.imageData:getDimensions() end
  function api.ImageData:getPixel(x,y) return self.imageData:getPixel((x or 1)-1,(y or 1)-1) end
  function api.ImageData:setPixel(x,y,c)
    if(type(c) ~= "table") then c = _GetColor(c) end -- accept palette color or {r,g,b}
    self.imageData:setPixel((x or 1)-1,(y or 1)-1,unpack(c))
    return self
  end
  function api.ImageData:map(mf)
    self.imageData:mapPixel(
      function(x,y,r,g,b,a)
        local newCol = mf(x+1,y+1,_GetColorID(r,g,b,a))
        newCol = newCol and _GetColor(newCol) or {r,g,b,a}
        return unpack(newCol)
      end)
    return self
  end
  function api.ImageData:height() return self.imageData:getHeight() end
  function api.ImageData:width() return self.imageData:getWidth() end
  function api.ImageData:paste(sprData,dx,dy,sx,sy,sw,sh) self.imageData:paste(sprData.imageData,(dx or 1)-1,(dy or 1)-1,(sx or 1)-1,(sy or 1)-1,sw or sprData:width(), sh or sprData:height()) return self end
  function api.ImageData:quad(x,y,w,h) return love.graphics.newQuad(x-1,y-1,w or self:width(),h or self:height(),self:width(),self:height()) end
  function api.ImageData:image() return api.Image(self) end
  function api.ImageData:export(filename) return self.imageData:encode("png",filename and (filename..".png") or nil) end
  function api.ImageData:enlarge(scale)
    local scale = api.floor(scale or 1)
    if scale <= 0 then scale = 1 end --Protection
    if scale == 1 then return self end
    local newData = api.ImageData(self:width()*scale,self:height()*scale)
    self:map(function(x,y,c)
      for iy=1, scale do for ix=1, scale do
        newData:setPixel((x-1)*scale + ix,(y-1)*scale + iy,c)
      end end
    end)
    return newData
  end

  api.SpriteSheet = _Class("Liko12.spriteSheet")
  function api.SpriteSheet:initialize(img,w,h)
    self.img, self.w, self.h = img, w, h
    self.cw, self.ch, self.quads = self.img:width()/self.w, self.img:height()/self.h, {}
    for y=1,self.h do for x=1,self.w do
      table.insert(self.quads,self.img:quad(x*self.cw-(self.cw-1),y*self.ch-(self.ch-1),self.cw,self.ch))
    end end
  end
  function api.SpriteSheet:image() return self.img end
  function api.SpriteSheet:data() return self.img:data() end
  function api.SpriteSheet:quad(id) return self.quads[id] end
  function api.SpriteSheet:rect(id) local x,y,w,h = self.quads[id]:getViewport() return x+1,y+1,w,h end
  function api.SpriteSheet:draw(id,x,y,r,sx,sy) self.img:draw(x,y,r,sx,sy,self.quads[id]) _ShouldDraw = true return self end
  function api.SpriteSheet:extract(id) return api.ImageData(8,8):paste(self:data(),1,1,self:rect(id)) end

  function api.Sprite(id,x,y,r,sx,sy,sheet) (sheet or api.SpriteMap):draw(id,x,y,r,sx,sy) end
  function api.SpriteGroup(id,x,y,w,h,sx,sy,sheet)
    local sx,sy = api.floor(sx or 1), api.floor(sy or 1)
    for spry = 1, h or 1 do for sprx = 1, w or 1 do
      (sheet or api.SpriteMap):draw((id-1)+sprx+(spry*24-24),x+(sprx*sx*8-sx*8),y+(spry*sy*8-sy*8),0,sx,sy)
    end end
  end

  --Cursors Section--
  api._CurrentCursor = "normal"
  api._Cursors = {}
  api._CachedCursors = {}

  function api.newCursor(data,name,hotx,hoty)
    api._Cursors[name] = {data = data, hotx = hotx or 1, hoty = hoty or 1}
    api._CachedCursors[name or "custom"] = love.mouse.newCursor(api._Cursors[name].data:enlarge(_ScreenScale).imageData,(api._Cursors[name].hotx-1)*_ScreenScale,(api._Cursors[name].hoty-1)*_ScreenScale)
  end

  function api.loadDefaultCursors()
    api.newCursor(api.EditorSheet:extract(1),"normal",2,2)
    api.newCursor(api.EditorSheet:extract(2),"handrelease",3,2)
    api.newCursor(api.EditorSheet:extract(3),"handpress",3,4)
    api.newCursor(api.EditorSheet:extract(4),"hand",5,5)
    api.newCursor(api.EditorSheet:extract(5),"cross",4,4)
    api.setCursor(api._CurrentCursor)
  end

  function api.setCursor(name)
    if not api._CachedCursors[name] then api._CachedCursors[name or "custom"] = love.mouse.newCursor(api._Cursors[name].data:enlarge(_ScreenScale).imageData,(api._Cursors[name].hotx-1)*_ScreenScale,(api._Cursors[name].hoty-1)*_ScreenScale) end
    love.mouse.setCursor(api._CachedCursors[name]) api._CurrentCursor = name or "custom"
  end

  function api.clearCursorsCache() api._CachedCursors = {} api.setCursor(api._CurrentCursor) end

  --Math Section--
  api.ostime = os.time

  function api.rand_seed(newSeed)
    love.math.setRandomSeed(newSeed)
  end

  function api.rand(minV,maxV) return love.math.random(minV,maxV) end

  function api.floor(num) return math.floor(num) end

  --Gui Function--
  function api.isInRect(x,y,rect)
    if x >= rect[1] and y >= rect[2] and x <= rect[1]+rect[3] and y <= rect[2]+rect[4] then return true end return false
  end

  function api.whereInGrid(x,y, grid) --Grid X, Grid Y, Grid Width, Grid Height, NumOfCells in width, NumOfCells in height
    local gx,gy,gw,gh,cw,ch = unpack(grid)
    if api.isInRect(x,y,{gx,gy,gw,gh}) then
      local clw, clh = api.floor(gw/cw), api.floor(gh/ch)
      local x, y = x-gx, y-gy
      local hx = api.floor(x/clw)+1 hx = hx <= cw and hx or hx-1
      local hy = api.floor(y/clh)+1 hy = hy <= ch and hy or hy-1
      return hx,hy
    end
    return false, false
  end

  -- should allow customizing this
  local button_mapping = {
    -- player 1
    {{"left"}, {"right"}, {"up"}, {"down"}, {"z", "c", "x"}, {"x", "v", "m"}},
    -- player 2
    {{"s"}, {"f"}, {"e"}, {"d"}, {"lshift", "tab"}, {"a", "q"}}}

  function api.btn(n, p)
    local keys = button_mapping[(p or 0) + 1][n+1]
    if(keys) then
      return love.keyboard.isDown(unpack(keys))
    end
  end

  function api.getMPos()
    return _ScreenToLiko(love.mouse.getPosition())
  end

  function api.isMDown(b) return love.mouse.isDown(b) end

  --FileSystem Function--
  if not noFS then
    api.fs = {}
    function api.fs.write(path,data)
      return love.filesystem.write("/data/"..path,data)
    end
    
    function api.fs.exists(path) return love.filesystem.exists("/data/"..path) end
    function api.fs.isDir(path) return love.filesystem.isDirectory("/data/"..path) end
    function api.fs.isFile(path) return love.filesystem.isFile("/data/"..path) end
    function api.fs.mkDir(path) return love.filesystem.createDirectory("/data/"..path) end
    function api.fs.dirItems(path) return love.filesystem.getDirectoryItems("/data/"..path) end
    function api.fs.del(path) return love.filesystem.remove("/data/"..path) end

    function api.fs.read(path) return love.filesystem.read("/data/"..path) end
  end

  --Misc Functions--
  function api.keyrepeat(state) love.keyboard.setKeyRepeat(state) end
  function api.showkeyboard(state) love.keyboard.setTextInput(state) end
  function api.isMobile() return _isMobile or false end
  
  api.TextBuffer = love.filesystem.load("/libraries/textbuffer.lua")()
  api.MapObj = love.filesystem.load("/libraries/map.lua")()

  --Spritesheet--
  api.EditorSheet = api.SpriteSheet(api.Image("/editorsheet.png"),24,12)
  api.SpriteMap = sprsheetmap or api.SpriteSheet(api.ImageData(24*8,12*8):image(),24,12)
  api.TileMap = carttilemap or api.MapObj()

  return api
end

local sapi = newAPI()
sapi.newAPI = newAPI

return sapi
