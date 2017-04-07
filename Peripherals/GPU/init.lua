local perpath = select(1,...) --The path to the gpu folder
local events = require("Engine.events")
local coreg = require("Engine.coreg")

return function(config) --A function that creates a new GPU peripheral.
  
  --Load the config--
  local _LIKO_W, _LIKO_H = config._LIKO_W or 192, config._LIKO_H or 128 --LIKO screen width.
  local _LIKO_X, _LIKO_Y = 0,0 --LIKO12 Screen padding in the HOST screen.
  
  local _HOST_W, _HOST_H = love.graphics.getDimensions() --The host window size.
  
  local _GIFScale = math.floor(config._GIFScale or 2) --The gif scale factor (must be int).
  local _GIFStartKey = config._GIFStartKey or "f8"
  local _GIFEndKey = config._GIFEndKey or "f9"
  local _GIFPauseKey = config._GIFPauseKey or "f12"
  local _GIFFrameTime = (config._GIFFrameTime or 1/60)*2  --The delta timr between each gif frame.
  local _GIFTimer, _GIFRec = 0
  
  local _LIKOScale = math.floor(config._LIKOScale or 3) --The LIKO12 screen scale to the host screen scale.
  
  local _FontW, _FontH = config._FontW or 4, config._FontH or 5 --Font character size
  local _FontChars = config._FontChars or 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?[](){}.,;:<>+=%#^*~/\\|$@&`"\'-_ ' --Font chars
  local _FontPath, _FontExtraSpacing = config._FontPath or "/Engine/font5x4.png", config._FontExtraSpacing or 1 --Font image path, and how many extra spacing pixels between every character.
  
  --The colorset (PICO-8 Palette by default)
  local _ColorSet = config._ColorSet or {
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
  } --The colorset of the gpu
  
  _ColorSet[0] = {0,0,0,0} --Color index 0 must be always transparent.
  
  local _ClearOnRender = config._ClearOnRender --Should clear the screen when render, some platforms have glitches when this is disabled.
  if type(_ClearOnRender) == "nil" then _ClearOnRender = true end --Defaults to be enabled.
  local cpukit if config.CPUKit then cpukit = config.CPUKit end --Get the cpukit (api) for triggering mouse events.
  --End of config loading--
  
  local _ShouldDraw = false --This flag means that the gpu has to update the screen for the user.
  
  --Hook the resize function--
  events:register("love:resize",function(w,h) --Do some calculations
    _HOST_W, _HOST_H = w, h
    local TSX, TSY = w/_LIKO_W, h/_LIKO_H --TestScaleX, TestScaleY
    if TSX < TSY then
      _LIKOScale = TSX
      _LIKO_X, _LIKO_Y = 0, (_HOST_H-_LIKO_H*_LIKOScale)/2
    else
      _LIKOScale = TSY
      _LIKO_X, _LIKO_Y = (_HOST_W-_LIKO_W*_LIKOScale)/2, 0
    end
    _ShouldDraw = true
  end)
  
  --Hook to some functions to redraw (when the window is moved, got focus, etc ...)
  events:register("love:focus",function(f) if f then _ShouldDraw = true end end) --Window got focus.
  events:register("love:visible",function(v) if v then _ShouldDraw = true end end) --Window got visible.
  
  --Initialize the gpu--
  love.graphics.setDefaultFilter("nearest","nearest") --Set the scaling filter to the nearest pixel.
  local _ScreenCanvas = love.graphics.newCanvas(_LIKO_W, _LIKO_H) --Create the screen canvas.
  local _GIFCanvas = love.graphics.newCanvas(_LIKO_W*_GIFScale,_LIKO_H*_GIFScale) --Create the gif canvas, used to apply the gif scale factor.
  local _Font = love.graphics.newImageFont(_FontPath, _FontChars, _FontExtraSpacing) --Create the default liko12 font.
  
  love.graphics.clear(0,0,0,255) --Clear the host screen.
  
  love.graphics.setCanvas(_ScreenCanvas) --Activate LIKO12 canvas.
  love.graphics.clear(0,0,0,255) --Clear LIKO12 screen for the first time.
  
  events:trigger("love:resize", _HOST_W, _HOST_H) --Calculate LIKO12 scale to the host window for the first time.
  
  love.graphics.setFont(_Font) --Activate the default font.
  
  --Post initialization (Setup the in liko12 gpu settings)--
  
  local gpuName, gpuVersion, gpuVendor, gpuDevice = love.graphics.getRendererInfo() --Used to apply some device specific bugfixes.
  --love.filesystem.write("/GPUInfo.txt",gpuName..";"..gpuVersion..";"..gpuVendor..";"..gpuDevice)
  
  local _DrawPalette = {} --The palette mapping for all drawing opereations expect image:draw (p = 1).
  local _ImagePalette = {} --The palette mapping for image:draw opereations (p = 2).
  local _ImageTransparent = {} --The transparent colors palette, 1 for solid, 0 for transparent.
  local _DisplayPalette = {} --The final display shader palette, converts the red pixel values to a palette color.
  
  --Build the default palettes.
  for i=1,16 do
    _ImageTransparent[i] = (i==1 and 0 or 1) --Black is transparent by default.
    _DrawPalette[i] = i-1
    _ImagePalette[i] = i-1
    _DisplayPalette[i] = _ColorSet[i]
  end
  _DisplayPalette[17] = {0,0,0,0} --A bug in unpack ???
  _DrawPalette[17] = 0
  _ImagePalette[17] = 0
  _ImageTransparent[17] = 0
  
  --Note: Those are modified version of picolove shaders.
  --The draw palette shader
  local _DrawShader = love.graphics.newShader([[
  extern float palette[16];
  
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    int index=int(color.r*255.0+0.5);
    float ta=float(Texel(texture,texture_coords).a);
    return vec4(palette[index]/255.0, 0.0, 0.0, color.a*ta);
  }]])
  _DrawShader:send('palette', unpack(_DrawPalette)) --Upload the initial palette.
  
  --The image:draw palette shader
  local _ImageShader = love.graphics.newShader([[
  extern float palette[16];
  extern float transparent[16];
  
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    int index=int(Texel(texture, texture_coords).r*255.0+0.5);
    float ta=float(Texel(texture,texture_coords).a);
    return vec4(palette[index]/255.0, 0.0, 0.0, transparent[index]*ta);
  }]])
  _ImageShader:send('palette', unpack(_ImagePalette)) --Upload the inital palette.
  _ImageShader:send('transparent', unpack(_ImageTransparent)) --Upload the initial palette.
  
  --The final display shader.
  local _DisplayShader = love.graphics.newShader([[
    extern vec4 palette[16];
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      int index=int(Texel(texture, texture_coords).r*255.0+0.5);
      float ta=float(Texel(texture,texture_coords).a);
      // lookup the colour in the palette by index
      vec4 col=palette[index]/255.0;
      col.a = col.a*color.a*ta;
      return col;
  }]])
  _DisplayShader:send('palette', unpack(_DisplayPalette)) --Upload the colorset.
  
  local ofs = {} --Offsets table.
  ofs.screen = {0,0} --The offset of all the drawing opereations.
  ofs.point = {0,0} --The offset of GPU.point/s.
  ofs.print = {-1,-1} --The offset of GPU.print.
  ofs.print_grid = {-1,-1} --The offset of GPU.print with grid mode.
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
  ofs.quad = {-1,-1}
  
  if gpuVersion == "OpenGL ES 3.1 v1.r7p0-03rel0.b8759509ece0e6dda5325cb53763bcf0" then
    --GPU glitch fix for this driver, happens at my samsung j700h
    ofs.screen = {0,-1}
    ofs.print = {-1,0}
    ofs.print_grid = {-2,0}
    ofs.rect = {-1,0}
    ofs.image = {-1,0}
    ofs.quad = {-1,0}
  end
  
  love.graphics.translate(unpack(ofs.screen)) --Offset all the drawing opereations.
  love.graphics.setShader(_DrawShader) --Activate the drawing shader.
  
  local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS" --Used to disable the cursors system (partly)
  
  --Internal Functions--
  local function _HostToLiko(x,y) --Convert a position from HOST screen to LIKO12 screen.
    --x, y = x-_ScreenX, y-_ScreenY
    return math.floor((x - _LIKO_X)/_LIKOScale )+1, math.floor((y - _LIKO_Y)/_LIKOScale)+1
  end
  
  local function _GetColor(c) return _ColorSet[c or 1] or _ColorSet[0] end --Get the (rgba) table of a color id.
  local function _GetColorID(r,g,b,a) --Get the color id by the (rgba) table.
    local a = type(a) == "nil" and 255 or a
    for id, col in pairs(_ColorSet) do
      if col[1] == r and col[2] == g and col[3] == b and col[4] == a then
        return id
      end
    end
    return 0
  end
  
  --Convert from LIKO12 palette to real colors.
  local function _ExportImage(x,y, r,g,b,a)
    if a == 0 then return 0,0,0,0 end
    if _ImageTransparent[r+1] == 0 then return 0,0,0,0 end
    return unpack(_ColorSet[r+1])
  end
  
  --Used for print function (in grid mode)
  local function magiclines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
  end
  
  --Excute a LIKO12 api function (to handle errors)
  local function exe(...)
    local args = {...}
    if args[1] then
      local nargs = {}
      for k,v in pairs(args) do --Clone the args, removing the first one
        if type(k) == "number" then
          nargs[k-1] = v
        else
          nargs[k] = v
        end
      end
      return unpack(nargs)
    else
      return error(args[2])
    end
  end
  
  --GifRecorder
  local _GIF = love.filesystem.load(perpath.."gif.lua")( _ColorSet, _GIFScale, _LIKO_W, _LIKO_H ) --Load the gif library
  --To handle gif control buttons
  events:register("love:keypressed", function(key,sc,isrepeat)
    if key == _GIFStartKey then
      if _GIFRec then return end --If there is an already in progress gif
      if love.filesystem.exists("/~gifrec.gif") then
        _GIFRec = _GIF.continue("/~gifrec.gif")
        return
      end
      _GIFRec = _GIF.new("/~gifrec.gif")
    elseif key == _GIFEndKey then
      if not _GIFRec then
        if love.filesystem.exists("/~gifrec.gif") then
          _GIFRec = _GIF.continue("/~gifrec.gif")
        else return end
      end
      _GIFRec:close()
      _GIFRec = nil
      love.filesystem.write("/LIKO12-"..os.time()..".gif",love.filesystem.read("/~gifrec.gif"))
      love.filesystem.remove("/~gifrec.gif")
    elseif key == _GIFPauseKey then
      if not _GIFRec then return end
      _GIFRec.file:flush()
      _GIFRec.file:close()
      _GIFRec = nil
    end
  end)
  --To save the gif before rebooting.
  events:register("love:reboot",function(args)
    if _GIFRec then
      _GIFRec.file:flush()
      _GIFRec.file:close()
      _GIFRec = nil
      
      love.filesystem.write("/~gifreboot.gif",love.filesystem.read("/~gifrec.gif"))
      love.filesystem.remove("/~gifrec.gif")
    end
  end)
  --To save the gif before quitting.
  events:register("love:quit", function()
    if _GIFRec then
      _GIFRec.file:flush()
      _GIFRec.file:close()
      _GIFRec = nil
    end
    return false
  end)
  
  --Restoring the gif record if it was made by a reboot
  if love.filesystem.exists("/~gifreboot.gif") then
    if not _GIFRec then
      love.filesystem.write("/~gifrec.gif",love.filesystem.read("/~gifreboot.gif"))
      love.filesystem.remove("/~gifreboot.gif")
      _GIFRec = _GIF.continue("/~gifrec.gif")
    end
  end
  
  --Mouse Hooks (To translate them to LIKO12 screen)--
  events:register("love:mousepressed",function(x,y,b,istouch)
    local x,y = _HostToLiko(x,y)
    events:trigger("GPU:mousepressed",x,y,b,istouch)
    if cpukit then cpukit.triggerEvent("mousepressed",x,y,b,istouch) end
  end)
  events:register("love:mousemoved",function(x,y,dx,dy,istouch)
    local x,y = _HostToLiko(x,y)
    local dx, dy = _HostToLiko(dx,dy)
    events:trigger("GPU:mousemoved",x,y,dx,dy,istouch)
    if cpukit then cpukit.triggerEvent("mousemoved",x,y,dx,dy,istouch) end
  end)
  events:register("love:mousereleased",function(x,y,b,istouch)
    local x,y = _HostToLiko(x,y)
    events:trigger("GPU:mousereleased",x,y,b,istouch)
    if cpukit then cpukit.triggerEvent("mousereleased",x,y,b,istouch) end
  end)
  events:register("love:wheelmoved",function(x,y)
    events:trigger("GPU:wheelmoved",x,y)
    if cpukit then cpukit.triggerEvent("wheelmoved",x,y) end
  end)
  
  --Touch Hooks (To translate them to LIKO12 screen)--
  events:register("love:touchpressed",function(id,x,y,dx,dy,p)
    local x,y = _HostToLiko(x,y)
    local dx, dy = _HostToLiko(dx,dy)
    events:trigger("GPU:touchpressed",id,x,y,dx,dy,p)
    if cpukit then cpukit.triggerEvent("touchpressed",id,x,y,dx,dy,p) end
  end)
  events:register("love:touchmoved",function(id,x,y,dx,dy,p)
    local x,y = _HostToLiko(x,y)
    local dx, dy = _HostToLiko(dx,dy)
    events:trigger("GPU:touchmoved",id,x,y,dx,dy,p)
    if cpukit then cpukit.triggerEvent("touchmoved",id,x,y,dx,dy,p) end
  end)
  events:register("love:touchreleased",function(id,x,y,dx,dy,p)
    local x,y = _HostToLiko(x,y)
    local dx, dy = _HostToLiko(dx,dy)
    events:trigger("GPU:touchreleased",id,x,y,dx,dy,p)
    if cpukit then cpukit.triggerEvent("touchreleased",id,x,y,dx,dy,p) end
  end)
  
  --The api starts here--
  local GPU = {}
  
  local flip = false --Is the code waiting for the screen to draw, used to resume the coroutine.
  local Clip = false --The current active clipping region.
  local ColorStack = {} --The colors stack (pushColor,popColor)
  local PaletteStack = {} --The palette stack (pushPalette,popPalette)
  local printCursor = {x=1,y=1,bgc=1} --The print grid cursor pos.
  local TERM_W, TERM_H = math.floor(_LIKO_W/(_FontW+1)), math.floor(_LIKO_H/(_FontH+2)) --The size of characters that the screen can fit.
  
  --Those explains themselves.
  function GPU.screenSize() return true, _LIKO_W, _LIKO_H end
  function GPU.screenWidth() return true, _LIKO_W end
  function GPU.screenHeight() return true, _LIKO_H end
  function GPU.termSize() return true, TERM_W, TERM_H end
  function GPU.termWidth() return true, TERM_W end
  function GPU.termHeight() return true, TERM_H end
  function GPU.fontSize() return true, _FontW, _FontH end
  function GPU.fontWidth() return true, _FontW end
  function GPU.fontHeight() return true, _FontH end
  
  --Call with color id to set the active color.
  --Call with no args to get the current acive color id.
  function GPU.color(id)
    if id then
      if type(id) ~= "number" then return false, "The color id must be a number." end --Error
      if id > 16 or id < 0 then return false, "The color id is out of range." end --Error
      id = math.floor(id) --Remove the float digits.
      if id == 0 then --Set the active color.
        love.graphics.setColor(0,0,0,0)
      else
        love.graphics.setColor(id-1,0,0,255)
      end
      return true --It ran successfuly.
    else
      local r,g,b,a = love.graphics.getColor()
      if a == 0 then return true,0 end
      return true, r+1 --Return the current color.
    end
  end
  
  --Push the current active color to the ColorStack.
  function GPU.pushColor()
    table.insert(ColorStack,exe(GPU.color())) --Add the active color id to the stack.
    return true --It ran successfully.
  end
  
  --Pop the last color from the ColorStack and set it to the active color.
  function GPU.popColor()
    if #ColorStack == 0 then return false, "No more colors to pop." end --Error
    exe(GPU.color(ColorStack[#ColorStack])) --Set the last color in the stack to be the active color.
    table.remove(ColorStack,#ColorStack) --Remove the last color in the stack.
    return true --It ran successfully
  end
  
  --Map pallete colors
  function GPU.pal(c0,c1,p)
    local drawchange = false  --Has any changes been made to the draw palette (p=1).
    local imagechange = false  --Has any changes been made to the image:draw palette (p=2).
    
    --Error check all the arguments.
    if c0 and type(c0) ~= "number" then return false, "C0 must be a number, provided: "..type(c0) end
    if c1 and type(c1) ~= "number" then return false, "C1 must be a number, provided: "..type(c1) end
    if p and type(p) ~= "number" then return false, "P must be a number, provided: "..type(p) end
    if c0 then c0 = math.floor(c0) end
    if c1 then c1 = math.floor(c1) end
    if p then p = math.floor(p) end
    if c0 and (c0 < 1 or c0 > 16) then return false, "C0 is out of range ("..c0..") expected [1,16]" end
    if c1 and (c1 < 1 or c1 > 16) then return false, "C1 is out of range ("..c1..") expected [1,16]" end
    if p and (p < 1 or p > 2) then return false, "P is out of range ("..p..") expected [1,2]" end
    
    --Reset the palettes.
    if (not c0) and (not c1) then
      for i=1, 16 do
        if _DrawPalette[i] ~= i-1 and ((not p) or p == 1) then
          drawchange = true
          _DrawPalette[i] = i-1
        end
        
        if _ImagePalette[i] ~= i-1 and ((not p) or p > 1) then
          imagechange = true
          _ImagePalette[i] = i-1
        end
      end
    --Reset a specific color
    elseif not(c1) then
      if ((not p) or p == 1) and _DrawPalette[c0] ~= c0-1 then
        drawchange = true
        _DrawPalette[c0] = c0-1
      end
      
      if ((not p) or p > 1) and _ImagePalette[c0] ~= c0-1 then
        imagechange = true
        _ImagePalette[c0] = c0-1
      end
    --Modify the palette
    elseif c0 and c1 then
      if ((not p) or p == 1) and _DrawPalette[c0] ~= c1-1 then
        drawchange = true
        _DrawPalette[c0] = c1-1
      end
      
      if ((not p) or p > 1) and _ImagePalette[c0] ~= c1-1 then
        imagechange = true
        _ImagePalette[c0] = c1-1
      end
    end
    --If changes has been made then upload the data to the shaders.
    if drawchange then _DrawShader:send('palette',unpack(_DrawPalette)) end
    if imagechange then _ImageShader:send('palette',unpack(_ImagePalette)) end
    return true --It ran successfully.
  end
  
  function GPU.palt(c,t)
    local changed = false
    if c then
      if type(c) ~= "number" then return false, "Color must be a number, provided: "..type(c) end
      c = math.floor(c)
      if (c < 1 or c > 16) then return false, "Color out of range ("..c..") expected [1,16]" end
      
      if _ImageTransparent[c] == (t and 1 or 0) then
        _ImageTransparent[c] = (t and 0 or 1)
        changed = true
      end
    else
      for i=2,16 do
        if _ImageTransparent[i] == 0 then
          changed = true
          _ImageTransparent[i] = 1
        end
      end
      if _ImageTransparent[1] == 1 then
        changed = true
        _ImageTransparent[1] = 0
      end
    end
    if changed then _ImageShader:send('transparent', unpack(_ImageTransparent)) end
    return true
  end
  
  function GPU.pushPalette()
    local pal = {}
    pal.draw = {}
    pal.img = {}
    pal.trans = {}
    for i=1, 16 do
      table.insert(pal.draw,_DrawPalette[i])
      table.insert(pal.img,_ImagePalette[i])
      table.insert(pal.trans,_ImageTransparent[i])
    end
    table.insert(PaletteStack,pal)
    return true
  end
  
  function GPU.popPalette()
    if #PaletteStack == 0 then return false, "No more palettes to pop." end --Error
    local pal = PaletteStack[#PaletteStack]
    local drawchange, imgchange, transchange = false,false,false
    for i=1,16 do
      if _DrawPalette[i] ~= pal.draw[i] then
        drawchange = true
        _DrawPalette[i] = pal.draw[i]
      end
      
      if _ImagePalette[i] ~= pal.img[i] then
        imgchange = true
        _ImagePalette[i] = pal.img[i]
      end
      
      if _ImageTransparent[i] ~= pal.trans[i] then
        transchange = true
        _ImageTransparent[i] = pal.trans[i]
      end
    end
    if drawchange then _DrawShader:send('palette',unpack(_DrawPalette)) end
    if imgchange then _ImageShader:send('palette',unpack(_ImagePalette)) end
    if transchange then _ImageShader:send('transparent', unpack(_ImageTransparent)) end
    table.remove(PaletteStack,#PaletteStack)
    return true
  end
  
  --Suspend the coroutine till the screen is updated
  function GPU.flip()
    _ShouldDraw = true -- Incase if no changes are made so doesn't suspend forever
    flip = true
    return 2 --Do not resume automatically
  end
  
  --Camera Functions
  function GPU.cam(mode,a,b)
    if mode and type(mode) ~= "string" then return false, "Mode must be a string, providied: "..type(mode) end
    if a and type(a) ~= "number" then return false, "a must be a number, providied: "..type(a) end
    if b and type(b) ~= "number" then return false, "b must be a number, providied: "..type(b) end
    
    if mode then
      if mode == "translate" then
        love.graphics.translate(a or 0,b or 0)
      elseif mode == "scale" then
        love.graphics.scale(a or 1, b or 1)
      elseif mode == "rotate" then
        love.graphics.rotate(a or 0)
      elseif mode == "shear" then
        love.graphics.shear(a or 0, b or 0)
      else
        return false, "Unknown mode: "..model
      end
    else
      exe(GPU.pushColor())
      love.graphics.origin()
      love.graphics.translate(unpack(ofs.screen))
      exe(GPU.popColor())
    end
    return true
  end
  
  function GPU.pushMatrix()
    return pcall(love.graphics.push)
  end
  
  function GPU.popMatrix()
    return pcall(love.graphics.pop)
  end
  
  function GPU.clip(x,y,w,h)
    if x then
      if type(x) ~= "number" then return false, "X must be a number, provided: "..type(x) end
      if type(y) ~= "number" then return false, "Y must be a number, provided: "..type(y) end
      if type(w) ~= "number" then return false, "W must be a number, provided: "..type(w) end
      if type(h) ~= "number" then return false, "H must be a number, provided: "..type(h) end
      Clip = {x-1,y-1,w,h}
      love.graphics.setScissor(unpack(Clip))
    else
      Clip = false
      love.graphics.setScissor()
    end
    return true
  end
  
  --Draw a rectangle filled, or lines only.
  --X pos, Y pos, W width, H height, L linerect, C colorid.
  function GPU.rect(x,y,w,h,l,c)
    local x,y,w,h,l,c = x, y, w, h, l or false, c --In case if they are not provided.
    
    --It accepts all the args as a table.
    if type(x) == "table" then
      x,y,w,h,l,c = unpack(x)
      l,c = l or false, c --In case if they are not provided.
    end
    
    --Args types verification
    if type(x) ~= "number" then return false, "X pos must be a number." end --Error
    if type(y) ~= "number" then return false, "Y pos must be a number." end --Error
    if type(w) ~= "number" then return false, "W width must be a number." end --Error
    if type(h) ~= "number" then return false, "H height must be a number." end --Error
    if type(l) ~= "boolean" then return false, "L linerect must be a number or nil." end --Error
    if c and type(c) ~= "number" then return false, "The color id must be a number or nil." end --Error
    
    --Remove float digits
    x,y,w,h,c = math.floor(x), math.floor(y), math.floor(w), math.floor(h), c and math.floor(c) or c
    
    if c then --If the colorid is provided, pushColor then set the color.
      exe(GPU.pushColor())
      exe(GPU.color(c))
    end
    
    --Apply the offset.
    if l then
      x,y = x+ofs.rect_line[1], y+ofs.rect_line[2] --Pos
      w,h = w+ofs.rectSize_line[1], h+ofs.rectSize_line[2] --Size
    else
      x,y = x+ofs.rect[1], y+ofs.rect[2] --Pos
      w,h = w+ofs.rectSize[1], h+ofs.rectSize[2] --Size
    end
    
    love.graphics.rectangle(l and "line" or "fill",x,y,w,h) _ShouldDraw = true --Draw and tell that changes has been made.
    
    if c then exe(GPU.popColor()) end --Restore the color from the stack.
    
    return true --It ran successfully
  end
  
  --Draws a circle filled, or lines only.
  function GPU.circle(x,y,r,l,c)
    local x,y,r,l,c = x, y, r, l or false, c --In case if they are not provided.
    
    --It accepts all the args as a table.
    if x and type(x) == "table" then
      x,y,r,l,c = unpack(x)
      l,c = l or false, c --In case if they are not provided.
    end
    
    --Args types verification
    if type(x) ~= "number" then return false, "X pos must be a number." end --Error
    if type(y) ~= "number" then return false, "Y pos must be a number." end --Error
    if type(r) ~= "number" then return false, "R radius must be a number." end --Error
    if type(l) ~= "boolean" then return false, "L linecircle must be a number or nil." end --Error
    if c and type(c) ~= "number" then return false, "The color id must be a number or nil." end --Error
    
    --Remove float digits
    x,y,r,c = math.floor(x), math.floor(y), math.floor(r), c and math.floor(c) or c
    
    if c then --If the colorid is provided, pushColor then set the color.
      exe(GPU.pushColor())
      exe(GPU.color(c))
    end
    
    --Apply the offset.
    if l then
      x,y,r = x+ofs.circle_line[1], y+ofs.circle_line[2], r+ofs.circle_line[3]
    else
      x,y,r = x+ofs.circle[1], y+ofs.circle[2], r+ofs.circle[3]
    end
    
    love.graphics.circle(l and "line" or "fill",x,y,r) _ShouldDraw = true --Draw and tell that changes has been made.
    
    if c then exe(GPU.popColor()) end --Restore the color from the stack.
    
    return true --It ran successfully
  end
  
  --Draws a triangle
  function GPU.triangle(x1,y1,x2,y2,x3,y3,l,col)
    local l = l or false
    
    if type(x1) ~= "number" then return false, "x1 must be a number, provided: "..type(x1) end
    if type(y1) ~= "number" then return false, "y1 must be a number, provided: "..type(y1) end
    if type(x2) ~= "number" then return false, "x2 must be a number, provided: "..type(x2) end
    if type(y2) ~= "number" then return false, "y2 must be a number, provided: "..type(y2) end
    if type(x3) ~= "number" then return false, "x3 must be a number, provided: "..type(x3) end
    if type(y3) ~= "number" then return false, "y3 must be a number, provided: "..type(y3) end
    if col and type(col) ~= "number" then return false, "color must be a number, provided: "..type(col) end
    
    x1,y1,x2,y2,x3,y3 = math.floor(x1),math.floor(y1),math.floor(x2),math.floor(y2),math.floor(x3),math.floor(y3)
    if col then col = math.floor(col) end
    if col and (col < 0 or col > 16) then return false, "color is out of range ("..col..") expected [0,16]" end
    
    if col then exe(GPU.pushColor()) exe(GPU.color(col)) end
    
    --Apply the offset
    if l then
      x1,y1,x2,y2,x3,y3 = x1 + ofs.triangle_line[1], y1 + ofs.triangle_line[2], x2 + ofs.triangle_line[1], y2 + ofs.triangle_line[2], x3 + ofs.triangle_line[1], y3 + ofs.triangle_line[2]
    else
      x1,y1,x2,y2,x3,y3 = x1 + ofs.triangle[1], y1 + ofs.triangle[2], x2 + ofs.triangle[1], y2 + ofs.triangle[2], x3 + ofs.triangle[1], y3 + ofs.triangle[2]
    end
    
    love.graphics.polygon(l and "line" or "fill", x1,y1,x2,y2,x3,y3)
    
    if col then exe(GPU.popColor()) end
    
    return true --It ran successfully
  end
  
  --Draw a polygon
  function GPU.polygon(...)
    local args = {...} --The table of args
    exe(GPU.pushColor()) --Push the current color.
    if not (#args % 2 == 0) then exe(GPU.color(args[#args])) table.remove(args,#args) end --Extract the colorid (if exists) from the args and apply it.
    for k,v in ipairs(args) do if type(v) ~= "number" then return false, "Arg #"..k.." must be a number." end end --Error
    if #args < 6 then return false, "Need at least three vertices to draw a polygon." end --Error
    for k,v in ipairs(args) do if (k % 2 == 0) then args[k] = v + ofs.polygon[2] else args[k] = v + ofs.polygon[1] end end --Apply the offset.
    love.graphics.polygon("fill",unpack(args)) _ShouldDraw = true --Draw the lines and tell that changes has been made.
    exe(GPU.popColor()) --Pop the last color in the stack.
    return true --It ran successfully.
  end
  
  --Draws a ellipse filled, or lines only.
  function GPU.ellipse(x,y,rx,ry,l,c)
    local x,y,rx,ry,l,c = x or 1, y or 1, rx or 1, ry or 1, l or false, c --In case if they are not provided.
    
    --It accepts all the args as a table.
    if x and type(x) == "table" then
      x,y,rx,ry,l,c = unpack(x)
    end
    
    if c then --If the colorid is provided, pushColor then set the color.
      exe(GPU.pushColor())
      exe(GPU.color(c))
    end
    
    --Apply the offset.
    if l then
      x,y,rx,ry = x+ofs.ellipse_line[1], y+ofs.ellipse_line[2], rx+ofs.ellipse_line[3], ry+ofs.ellipse_line[4]
    else
      x,y,rx,ry = x+ofs.ellipse[1], y+ofs.ellipse[2], rx+ofs.ellipse[3], ry+ofs.ellipse[4]
    end
    
    love.graphics.ellipse(l and "line" or "fill",x,y,rx,ry) _ShouldDraw = true --Draw and tell that changes has been made.
    
    if c then exe(GPU.popColor()) end --Restore the color from the stack.
    
    return true --It ran successfully
  end
  
  --Sets the position of the printing corsor when x,y are supplied
  --Or returns the current position of the printing cursor when x,y are not supplied
  function GPU.printCursor(x,y,bgc)
    if x or y or bgc then
      local x, y = x or printCursor.x, y or printCursor.y
      local bgc = bgc or printCursor.bgc
      if type(x) ~= "number" then return false, "X pos must be a number or nil." end --Error
      if type(y) ~= "number" then return false, "Y pos must be a number or nil." end --Error
      if type(bgc) ~= "number" then return false, "Background Color must be a number or nil." end --Error
      printCursor.x, printCursor.y = x, y --Set the cursor pos
      printCursor.bgc = bgc
      return true --It ran successfully.
    else
      return true, printCursor.x, printCursor.y, printCursor.bgc --Return the current cursor pos
    end
  end
  
  --Prints text to the screen,
  --Acts as a terminal print if x, y are not provided,
  --Or prints at the specific pos x, y
  function GPU.print(t,x,y,limit,align,r,sx,sy,ox,oy,kx,ky)
    local t = tostring(t) --Make sure it's a string
    if x and y then --Print at a specific position on the screen
      --Error handelling
      if type(x) ~= "number" then return false, "X position must be a number, provided: "..type(x) end
      if type(y) ~= "number" then return false, "Y position must be a number, provided: "..type(y) end
      if limit and type(limit) ~= "number" then return false, "Line limit be a number or a nil, provided: "..type(x) end
      if align then
        if type(align) ~= "string" then return false," Line align must be a string or a nil, provided: "..type(align) end
        if align ~= "left" or align ~= "center" or align ~= "right" or align ~= "justify" then
          return false, "Invalid line alignment '"..align.."' !"
        end
      end
      if r and type(r) ~= "number" then return false, "Rotation must be a number, provided: "..type(r) end
      if sx and type(sx) ~= "number" then return false, "X Scale factor must be a number, provided: "..type(sx) end
      if sy and type(sy) ~= "number" then return false, "Y Scale factor must be a number, provided: "..type(sy) end
      if ox and type(ox) ~= "number" then return false, "X Origin offset must be a number, provided: "..type(ox) end
      if oy and type(oy) ~= "number" then return false, "Y Origin offset must be a number, provided: "..type(oy) end
      if kx and type(kx) ~= "number" then return false, "X Shearing factor must be a number, provided: "..type(kx) end
      if ky and type(ky) ~= "number" then return false, "Y Shearing factor must be a number, provided: "..type(ky) end
      
      --Print to the screen
      if limit then --Wrapped
        love.graphics.printf(t,x+ofs.print[1],y+ofs.print[2],limit,align,r,sx,sy,ox,oy,kx,ky) _ShouldDraw = true
      else
        love.graphics.print(t,x+ofs.print[1],y+ofs.print[2],r,sx,sy,ox,oy,kx,ky) _ShouldDraw = true
      end
      
      return true --It ran successfully.
    else --Print to terminal pos
      local pc = printCursor --Shortcut
      
      local function togrid(gx,gy) --Covert to grid cordinates
        return math.floor((gx-1)*(_FontW+1))+1, math.floor((gy-1)*(_FontH+2))+1
      end
      
      --A function to draw the background rectangle
      local function drawbackground(gx,gy,gw)
        if pc.bgc == 0 or gw < 1 then return end --No need to draw the background
        gx,gy = togrid(gx,gy)
        GPU.rect(gx,gy, gw*(_FontW+1)+1,_FontH+2, false, pc.bgc)
      end
      
      --Draw directly without formatting nor updating the cursor pos.
      if y then
        drawbackground(pc.x, pc.y, t:len()) --Draw the background.
        local gx,gy = togrid(pc.x, pc.y)
        love.graphics.print(t,gx+1+ofs.print_grid[1],gy+1+ofs.print_grid[2]) --Print the text.
        pc.x = pc.x + t:len() --Update the x pos
        return true --It ran successfully
      end
      
      if type(x) == "nil" or x then t = t .. "\n\n" end --Auto newline after printing.
      
      local sw, sh = TERM_W*(_FontW+1), TERM_H*(_FontH+2) --Screen size
      local pre_spaces = string.rep(" ", pc.x-1) --The pre space for text wrapping to calculate
      local maxWidth, wrappedText = _Font:getWrap(pre_spaces..t, sw) --Get the text wrapped
      local linesNum = #wrappedText --Number of lines
      if linesNum > TERM_H-pc.y+1 then --It will go down of the screen, so shift the screen up.
        GPU.pushPalette() GPU.palt() GPU.pal() --Backup the palette and reset the palette.
        local extra = linesNum - (TERM_H-pc.y+1) --The extra lines that will draw out of the screen.
        local sc = exe(GPU.screenshot()) --Take a screenshot
        GPU.clear(1) --Clear the screen
        sc:image():draw(1, extra*(_FontH+2)*-1+1) --Draw the screen shifted up
        pc.y = pc.y-extra --Update the cursor pos.
        GPU.popPalette() --Restore the palette.
      end
      
      local drawY = pc.y
      
      --Iterate over the lines.
      for k, line in ipairs(wrappedText) do
        local printX = 1
        if k == 1 then line = line:sub(pre_spaces:len()+1,-1); printX = pc.x end --Remove the pre_spaces
        local linelen = line:len() --The line length
        drawbackground(printX,pc.y,linelen) --Draw the line background
        
        --Update the cursor pos
        pc.x = printX + line:len()
        if wrappedText[k+1] then pc.y = pc.y + 1 end --If there's a next line
      end
      
      love.graphics.printf(pre_spaces..t,1+1+ofs.print_grid[1],(drawY-1)*(_FontH+2)+1+1+ofs.print_grid[2],sw) _ShouldDraw = true --Print the text
      
      return true --It ran successfully.
    end
  end
  
  function GPU.printBackspace(c,skpCr)
    local c = c or printCursor.bgc
    if type(c) ~= "number" then return false, "Color must be a number value, provided: "..type(c) end
    local function cr() local s = exe(GPU.screenshot()):image() GPU.clear() s:draw(1,_FontH+2) end
    
    local function togrid(gx,gy) --Covert to grid cordinates
      return math.floor((gx-1)*(_FontW+1))+1, math.floor((gy-1)*(_FontH+2))+1
    end
    
    --A function to draw the background rectangle
    local function drawbackground(gx,gy,gw)
      if printCursor.bgc == 0 or gw < 1 then return end --No need to draw the background
      gx,gy = togrid(gx,gy)
      GPU.rect(gx,gy, gw*(_FontW+1)+1,_FontH+2, false, printCursor.bgc)
    end
      
    if printCursor.x > 1 then
      printCursor.x = printCursor.x-1
      drawbackground(printCursor.x,printCursor.y,1)
    elseif not skpCr then
      if printCursor.y > 1 then
        printCursor.y = printCursor.y - 1
        printCursor.x = TERM_W
      else
        printCursor.x = TERM_W
        cr()
      end
      drawbackground(printCursor.x,printCursor.y,1)
    end
    return true
  end
  
  --Clears the whole screen with black or the given color id.
  function GPU.clear(c)
    local c = math.floor(c or 1)
    if type(c) ~= "number" then return false, "The color id must be a number." end --Error
    if c > 16 or c < 0 then return false, "The color id is out of range." end --Error
    local a = c > 0 and 255 or 0
    if c == 0 then c = 1 end
    love.graphics.clear(c-1,0,0,a) _ShouldDraw = true
    return true --It ran successfully.
  end
  
  --Draws a point/s at specific location/s, accepts the colorid as the last args, x and y of points must be provided before the colorid.
  function GPU.points(...)
    local args = {...} --The table of args
    exe(GPU.pushColor()) --Push the current color.
    if not (#args % 2 == 0) then exe(GPU.color(args[#args])) table.remove(args,#args) end --Extract the colorid (if exists) from the args and apply it.
    for k,v in ipairs(args) do if type(v) ~= "number" then return false, "Arg #"..k.." must be a number." end end --Error
    for k,v in ipairs(args) do if (k % 2 == 0) then args[k] = v + ofs.point[2] else args[k] = v + ofs.point[1] end end --Apply the offset.
    love.graphics.points(unpack(args)) _ShouldDraw = true --Draw the points and tell that changes has been made.
    exe(GPU.popColor()) --Pop the last color in the stack.
    return true --It ran successfully.
  end
  GPU.point = GPU.points --Just an alt name :P.
  
  --Draws a line/s at specific location/s, accepts the colorid as the last args, x1,y1,x2 and y2 of points must be provided before the colorid.
  function GPU.lines(...)
    local args = {...} --The table of args
    exe(GPU.pushColor()) --Push the current color.
    if not (#args % 2 == 0) then exe(GPU.color(args[#args])) table.remove(args,#args) end --Extract the colorid (if exists) from the args and apply it.
    for k,v in ipairs(args) do if type(v) ~= "number" then return false, "Arg #"..k.." must be a number." end end --Error
    if #args < 4 then return false, "Need at least two vertices to draw a line." end --Error
    for k,v in ipairs(args) do if (k % 2 == 0) then args[k] = v + ofs.line[2] else args[k] = v + ofs.line[1] end end --Apply the offset.
    love.graphics.line(unpack(args)) _ShouldDraw = true --Draw the lines and tell that changes has been made.
    exe(GPU.popColor()) --Pop the last color in the stack.
    return true --It ran successfully.
  end
  GPU.line = GPU.lines --Just an alt name :P.
  --Image API--
  function GPU.quad(x,y,w,h,sw,sh)
    return pcall(love.graphics.newQuad,x,y,w,h,sw,sh)
  end
  
  function GPU.image(data)
    local Image
    if type(data) == "string" then --Load liko12 specialized image format
      local imageData = exe(GPU.imagedata(data))
      return true, imageData:image()
    elseif type(data) == "userdata" and data.typeOf and data:typeOf("ImageData") then
      Image = love.graphics.newImage(data)
      Image:setWrap("repeat")
      --imageData = exe(GPU.imagedata(Image))
    end
    
    local i = {}
    
    function i:draw(x,y,r,sx,sy,quad)
      local x, y, sx, sy = x or 1, y or 1, sx or 1, sy or 1
      GPU.pushColor()
      love.graphics.setShader(_ImageShader)
      love.graphics.setColor(255,255,255,255)
      if quad then
        love.graphics.draw(Image,quad,math.floor(x+ofs.quad[1]),math.floor(y+ofs.quad[2]),r,math.floor(sx),math.floor(sy))
      else
        love.graphics.draw(Image,math.floor(x+ofs.image[1]),math.floor(y+ofs.image[2]),r,math.floor(sx),math.floor(sy))
      end
      love.graphics.setShader(_DrawShader)
      GPU.popColor()
      _ShouldDraw = true
      return self
    end
    function i:size() return Image:getDimensions() end
    function i:width() return Image:getWidth() end
    function i:height() return Image:getHeight() end
    function i:data() return exe(GPU.imagedata(Image:getData())) end
    function i:quad(x,y,w,h) return love.graphics.newQuad(x-1,y-1,w or self:width(),h or self:height(),self:width(),self:height()) end
    
    return true, i
  end
  
  function GPU.imagedata(w,h)
    local imageData
    if h then
      imageData = love.image.newImageData(w,h)
      imageData:mapPixel(function() return 0,0,0,255 end)
    elseif type(w) == "string" then --Load specialized liko12 image format
      if w:sub(0,12) == "LK12;GPUIMG;" then
        w = w:gsub("\n","")
        local w,h,data = string.match(w,"LK12;GPUIMG;(%d+)x(%d+);(.+)")
        imageData = love.image.newImageData(w,h)
        local nextColor = string.gmatch(data,"%x")
        imageData:mapPixel(function(x,y,r,g,b,a)
          return tonumber(nextColor() or "0",16),0,0,255
        end)
      else
        imageData = love.image.newImageData(love.filesystem.newFileData(w,"image.png"))
      end
    elseif type(w) == "userdata" and w.typeOf and w:typeOf("ImageData") then
      imageData = w
    end
    
    local id = {}
    
    function id:size() return imageData:getDimensions() end
    function id:getPixel(x,y)
      if not x then return error("Must provide X") end
      if not y then return error("Must provide Y") end
      x,y = math.floor(x), math.floor(y)
      if x < 1 or x > self:width() or y < 1 or y > self:height() then
        return 1
      end
      local r,g,b,a = imageData:getPixel(x-1,y-1)
      return r+1
    end
    function id:setPixel(x,y,c)
      if type(c) ~= "number" then return error("Color must be a number, provided "..type(c)) end
      if not x then return error("Must provide X") end
      if not y then return error("Must provide Y") end
      x,y = math.floor(x), math.floor(y)
      if x < 1 or x > self:width() or y < 1 or y > self:height() then
        return self
      end
      c = math.floor(c) if c < 1 or c > 16 then return error("Color out of range ("..c..") expected [1,16]") end
      imageData:setPixel(x-1,y-1,c-1,0,0,255)
      return self
    end
    function id:map(mf)
      imageData:mapPixel(
      function(x,y,r,g,b,a)
        local c = mf(x+1,y+1,r+1)
        if c and type(c) ~= "number" then error("Color must be a number, provided "..type(c)) elseif c then c = math.floor(c) end
        if c and (c < 1 or c > 16) then return error("Color out of range ("..c..") expected [1,16]") end
        if c then return c-1,0,0,255 else return r,g,b,a end
      end)
      return self
    end
    function id:height() return imageData:getHeight() end
    function id:width() return imageData:getWidth() end
    function id:paste(expdata,dx,dy,sx,sy,sw,sh) local sprData = love.image.newImageData(love.filesystem.newFileData(expdata,"image.png")) imageData:paste(sprData,(dx or 1)-1,(dy or 1)-1,(sx or 1)-1,(sy or 1)-1,sw or sprData:getWidth(), sh or sprData:getHeight()) return self end
    function id:quad(x,y,w,h) return love.graphics.newQuad(x-1,y-1,w or self:width(),h or self:height(),self:width(),self:height()) end
    function id:image() return exe(GPU.image(imageData)) end
    function id:export() return imageData:encode("png"):getString() end
    function id:enlarge(scale)
      local scale = math.floor(scale or 1)
      if scale <= 0 then scale = 1 end --Protection
      if scale == 1 then return self end
      local newData = exe(GPU.imagedata(self:width()*scale,self:height()*scale))
      self:map(function(x,y,c)
        for iy=1, scale do for ix=1, scale do
          newData:setPixel((x-1)*scale + ix,(y-1)*scale + iy,c)
        end end
      end)
      return newData
    end
    function id:encode() --Export to liko12 format
      local data = "LK12;GPUIMG;"..self:width().."x"..self.height()..";"
      self:map(function(x,y,c) if x == 1 then data = data.."\n" end data = data..string.format("%X",c-1) end)
      return data
    end
    
    return true, id
  end
  
  function GPU.screenshot(x,y,w,h)
    local x, y, w, h = x or 1, y or 1, w or _LIKO_W, h or _LIKO_H
    if x and type(x) ~= "number" then return false, "X must be a number, provided: "..type(x) end
    if y and type(y) ~= "number" then return false, "Y must be a number, provided: "..type(y) end
    if w and type(w) ~= "number" then return false, "W must be a number, provided: "..type(w) end
    if h and type(h) ~= "number" then return false, "H must be a number, provided: "..type(h) end
    return true, exe(GPU.imagedata(_ScreenCanvas:newImageData(x-1,y-1,w,h)))
  end
  
  --Mouse API--
  
  --Returns the current position of the mouse.
  function GPU.getMPos()
    local x,y = _HostToLiko(love.mouse.getPosition()) --Convert the mouse position
    return true, x, y --And return it
  end
  
  --Returns if the given mouse button is down
  function GPU.isMDown(b)
    if type(b) ~= "number" then return false, "Button must be a number, provided: "..type(b) end --Error
    local b = math.floor(b)
    return true, love.mouse.isDown(b)
  end
  
  --Cursor API--
  local _Cursor = "none"
  local _CursorsCache = {}
  
  function GPU.cursor(imgdata,name,hx,hy)
    if type(imgdata) == "string" then --Set the current cursor
      if _Cursor == imgdata then return true end
      if (not _CursorsCache[imgdata]) and (imgdata ~= "none") then return false, "Cursor doesn't exists: "..imgdata end
      if _Cursor == "none" then love.mouse.setVisible(true) end
      _Cursor = imgdata
      if _Cursor == "none" then
        love.mouse.setVisible(false)
      elseif not _Mobile then
        love.mouse.setCursor(_CursorsCache[_Cursor].cursor)
      end
      return true --It ran successfully
    elseif type(imgdata) == "table" then --Create a new cursor from an image.
      if not( imgdata.enlarge and imgdata.export ) then return false, "Invalied image" end
      
      local name = name or "default"
      if type(name) ~= "string" then return false, "Name must be a string, provided: "..type(name) end
      
      local hx, hy = hx or 1, hy or 1
      if type(hx) ~= "number" then return false, "Hot X must be a number or a nil, provided: "..type(hx) end
      if type(hy) ~= "number" then return false, "Hot Y must be a number or a nil, provided: "..type(hy) end
      hx, hy = math.floor(hx)-1, math.floor(hy)-1
      
      local enimg = imgdata:enlarge(_LIKOScale)
      local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
      local gifimg = love.image.newImageData(love.filesystem.newFileData(imgdata:export(),"cursor.png"))
      limg:mapPixel(_ExportImage) --Convert image to have real colors.
      gifimg:mapPixel(_ExportImage)
      gifimg = love.graphics.newImage(gifimg)
      local hotx, hoty = hx*_LIKOScale, hy*_LIKOScale --Converted to host scale
      local cur = _Mobile and {} or love.mouse.newCursor(limg,hotx,hoty)
      
      _CursorsCache[name] = {cursor=cur,imgdata=imgdata,gifimg=gifimg,hx=hx,hy=hy}
      return true --It ran successfully
    elseif type(imgdata) == "nil" then
      return true, _Cursor, _CursorsCache[_Cursor].imgdata, _CursorsCache[_Cursor].hx+1, _CursorsCache[_Cursor].hy+1
    else --Invalied
      return false, "The first argument must be a string, image or nil"
    end
  end
  
  events:register("love:resize",function() --The new size will be calculated in the top, because events are called by the order they were registered with
    if _Mobile then return end
    for k, cursor in pairs(_CursorsCache) do
      local enimg = cursor.imgdata:enlarge(_LIKOScale)
      local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
      limg:mapPixel(_ExportImage)
      local hotx, hoty = cursor.hx*_LIKOScale, cursor.hy*_LIKOScale --Converted to host scale
      local cur = love.mouse.newCursor(limg,hotx,hoty)
      _Cursor = "none"; _CursorsCache[k].cursor = cur
    end
    exe(GPU.cursor(_Cursor))
  end)
  
  exe(GPU.cursor(exe(GPU.imagedata(1,1)):setPixel(1,1,8),"default"))
  exe(GPU.cursor(_Cursor))
  
  --End of API--
  
  love.graphics.setLineStyle("rough") --Set the line style.
  love.graphics.setLineJoin("miter") --Set the line join style.
  love.graphics.setPointSize(1) --Set the point size to 1px.
  love.graphics.setLineWidth(1) --Set the line width to 1px.
  love.graphics.setColor(_GetColor(1)) --Set the active color to black.
  love.mouse.setVisible(false)
  
  exe(GPU.clear()) --Clear the canvas for the first time.
  
  --Host to love.run when graphics is active--
  events:register("love:graphics",function()
    if _ShouldDraw then --When it's required to draw (when changes has been made to the canvas)
      love.graphics.setCanvas() --Quit the canvas and return to the host screen.
      love.graphics.push()
      love.graphics.setShader(_DisplayShader) --Activate the display shader
      love.graphics.origin() --Reset all transformations.
      if Clip then love.graphics.setScissor() end
      
      GPU.pushColor() --Push the current color to the stack.
      love.graphics.setColor(255,255,255,255) --I don't want to tint the canvas :P
      
      if _ClearOnRender then love.graphics.clear(0,0,0,255) end --Clear the screen (Some platforms are glitching without this).
      
      love.graphics.draw(_ScreenCanvas, _LIKO_X, _LIKO_Y, 0, _LIKOScale, _LIKOScale) --Draw the canvas.
      
      love.graphics.present() --Present the screen to the host & the user.
      love.graphics.setShader(_DrawShader) --Deactivate the display shader
      love.graphics.pop()
      love.graphics.setCanvas(_ScreenCanvas) --Reactivate the canvas.
      if Clip then love.graphics.setScissor(unpack(Clip)) end
      _ShouldDraw = false --Reset the flag.
      GPU.popColor() --Restore the active color.
      if flip then
        flip = false
        coreg:resumeCoroutine(true)
      end
    end
  end)
  
  events:register("love:update",function(dt)
    if not _GIFRec then return end
    _GIFTimer = _GIFTimer + dt
    if _GIFTimer >= _GIFFrameTime then
      _GIFTimer = _GIFTimer-_GIFFrameTime
      love.graphics.setCanvas() --Quit the canvas and return to the host screen.
      love.graphics.push()
      love.graphics.origin() --Reset all transformations.
      if Clip then love.graphics.setScissor() end
      
      GPU.pushColor() --Push the current color to the stack.
      love.graphics.setColor(255,255,255,255) --I don't want to tint the canvas :P
      
      love.graphics.setCanvas(_GIFCanvas)
      
      love.graphics.clear(0,0,0,255) --Clear the screen (Some platforms are glitching without this).
      
      love.graphics.setColor(255,255,255,255)
      
      love.graphics.setShader(_DisplayShader)
      
      love.graphics.draw(_ScreenCanvas, 0, 0, 0, _GIFScale, _GIFScale) --Draw the canvas.
      
      love.graphics.setShader()
      
      if _Cursor ~= "none" then --Draw the cursor
        local cx, cy = exe(GPU.getMPos())
        love.graphics.draw(_CursorsCache[_Cursor].gifimg,(cx-_CursorsCache[_Cursor].hx)*_GIFScale-1,(cy-_CursorsCache[_Cursor].hy)*_GIFScale-1,0,_GIFScale,_GIFScale)
      end
      
      love.graphics.setCanvas()
      love.graphics.setShader(_DrawShader)
      
      love.graphics.pop() --Reapply the offset.
      love.graphics.setCanvas(_ScreenCanvas) --Reactivate the canvas.
      if Clip then love.graphics.setScissor(unpack(Clip)) end
      GPU.popColor() --Restore the active color.
      
      _GIFRec:frame(_GIFCanvas:newImageData())
    end
  end)
  
  local devkit = {}
  devkit._LIKO_W = _LIKO_W
  devkit._LIKO_X = _LIKO_Y
  devkit._HOST_W = _HOST_W
  devkit._HOST_H = _HOST_H
  devkit._DrawPalette = _DrawPalette
  devkit._ImagePalette = _ImagePalette
  devkit._ImageTransparent = _ImageTransparent
  devkit._DrawShader = _DrawShader
  devkit._ImageShader = _ImageShader
  devkit._DisplayShader = _DisplayShader
  devkit._GIF = _GIF
  devkit._GIFScale = _GIFScale
  devkit._GIFStartKey = _GIFStartKey
  devkit._GIFEndKey = _GIFEndKey
  devkit._GIFPauseKey = _GIFPauseKey
  devkit._GIFFrameTime = _GIFFrameTime
  devkit._LIKOScale = _LIKOScale
  devkit._FontW = _FontW
  devkit._FontH = _FontH
  devkit._FontChars = _FontChars
  devkit._FontPath = _FontPath
  devkit._FontExtraSpacing = _FontExtraSpacing
  devkit._ColorSet = _ColorSet
  devkit._ClearOnRender = _ClearOnRender
  devkit._ScreenCanvas = _ScreenCanvas
  devkit._GIFCanvas = _GIFCanvas
  devkit._Font = _Font
  devkit.ofs = ofs
  devkit._HostToLiko = _HostToLiko
  devkit._GetColor = _GetColor
  devkit._GetColorID = _GetColorID
  devkit.exe = exe
  devkit._GIF = _GIF
  devkit.ColorStack = ColorStack
  devkit.TERM_W = TERM_W
  devkit.TERM_H = TERM_H
  devkit._CursorsCache = _CursorsCache
  
  return GPU, devkit --Return the table containing all of the api functions.
end
