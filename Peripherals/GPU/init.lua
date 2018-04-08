local perpath = select(1,...) --The path to the gpu folder
local events = require("Engine.events")
local coreg = require("Engine.coreg")

local bit = require("bit") --Require the bit operations library for use in VRAM
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

--Localized Lua Library
local floor = math.floor

local strformat = string.format

local json = require("Engine.JSON") --Used to save the calibrarion values.

--Wrapper for setColor to use 0-255 values
local function setColor(r,g,b,a)
  local r,g,b,a = r,g,b,a
  if type(r) == "table" then
    r,g,b,a = unpack(r)
  end
  if r then r = r/255 end
  if g then g = g/255 end
  if b then b = b/255 end
  if a then a = a/255 end
  
  love.graphics.setColor(r, g, b, a)
end

--Wrapper for getColor to use 0-255 values
local function getColor()
  local r,g,b,a = love.graphics.getColor()
  return floor(r*255), floor(g*255), floor(b*255), floor(a*255)
end

--Convert color from 0-255 to 0-1
local function colorTo1(r,g,b,a)
  local r,g,b,a = r,g,b,a
  if type(r) == "table" then r,g,b,a = unpack(r) end
  if r then r = r/255 end
  if g then g = g/255 end
  if b then b = b/255 end
  if a then a = a/255 end
  return r,g,b,a
end

--Convert color from 0-1 to 0-255
local function colorTo255(r,g,b,a)
  local r,g,b,a = r,g,b,a
  if type(r) == "table" then r,g,b,a = unpack(r) end
  if r then r = floor(r*255) end
  if g then g = floor(g*255) end
  if b then b = floor(b*255) end
  if a then a = floor(a*255) end
  return r,g,b,a
end

return function(config) --A function that creates a new GPU peripheral.
  
  --Load the config--
  local _LIKO_W, _LIKO_H = config._LIKO_W or 192, config._LIKO_H or 128 --LIKO screen width.
  local _LIKO_X, _LIKO_Y = 0,0 --LIKO12 Screen padding in the HOST screen.
  
  local _PixelPerfect = config._PixelPerfect --If the LIKO-12 screen must be drawn pixel perfect.
  
  --Gif Variables
  local _GIFScale = math.floor(config._GIFScale or 2) --The gif scale factor (must be int).
  local _GIFStartKey = config._GIFStartKey or "f8"
  local _GIFEndKey = config._GIFEndKey or "f9"
  local _GIFPauseKey = config._GIFPauseKey or "f7"
  local _GIFFrameTime = (config._GIFFrameTime or 1/60)*2  --The delta timr between each gif frame.
  local _GIFTimer, _GIFRec = 0
  local _GIFPChanged = false --A flag to indicate that the palette did change while gif recording
  local _GIFPStart --The gif starting palette compairing string.
  local _GIFPal --The gif palette string, should be 16*3 bytes long.
  
  --Screeshot Key
  local _ScreenshotKey = config._ScreenshotKey or "f5"
  local _ScreenshotScale = config._ScreenshotScale or 3
  
  local _LabelCaptureKey = config._LabelCaptureKey or "f6"
  
  local _LIKOScale = math.floor(config._LIKOScale or 3) --The LIKO12 screen scale to the host screen scale.
  
  local _FontW, _FontH = config._FontW or 4, config._FontH or 5 --Font character size
  local _FontChars = config._FontChars or 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?[](){}.,;:<>+=%#^*~/\\|$@&`"\'-_ ' --Font chars
  local _FontPath, _FontExtraSpacing = config._FontPath or "/Peripherals/GPU/font4x5.png", config._FontExtraSpacing or 1 --Font image path, and how many extra spacing pixels between every character.
  
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
  
  local _DefaultColorSet = {} --The default palette for the operating system.
  
  for k,v in ipairs(_ColorSet) do
    _ColorSet[k-1] = v
    _DefaultColorSet[k-1] = v
  end
  _ColorSet[16] = nil
  
  local _ClearOnRender = config._ClearOnRender --Should clear the screen when render, some platforms have glitches when this is disabled.
  if type(_ClearOnRender) == "nil" then _ClearOnRender = true end --Defaults to be enabled.
  local cpukit if config.CPUKit then cpukit = config.CPUKit end --Get the cpukit (api) for triggering mouse events.
  
  local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS" --Used to disable the cursors system (partly)
  
  --HOST Window Initialization--
  local _HOST_W, _HOST_H = _LIKO_W*_LIKOScale, _LIKO_H*_LIKOScale --The host window size.
  if _Mobile then _HOST_W, _HOST_H = 0,0 end
  
  if not love.window.isOpen() then
    love.window.setMode(_HOST_W,_HOST_H,{
      vsync = 1,
      resizable = true,
      minwidth = _LIKO_W,
      minheight = _LIKO_H
    })
    
    if config.title then
      love.window.setTitle(config.title)
    else
      love.window.setTitle("LIKO-12 ".._LVERSION)
    end
    love.window.setIcon(love.image.newImageData("icon.png"))
  end
  
  events:register("love:quit", function()
    if love.window.isOpen() then
      love.graphics.setCanvas()
      love.window.close()
    end
    return false
  end)
  
  _HOST_W, _HOST_H = love.graphics.getDimensions()
  
  --End of config loading--
  
  local _Flipped = falde --This flag means that the screen has been flipped
  local _ShouldDraw = false --This flag means that the gpu has to update the screen for the user.
  local _AlwaysDraw = false --This flag means that the gpu has to always update the screen for the user.
  local _DevKitDraw = false --This flag means that the gpu has to always update the screen for the user, set by other peripherals
  local _AlwaysDrawTimer = 0 --This timer is only used on mobile devices to keep drawing the screen when the user changes the orientation.
  
  --Hook the resize function--
  events:register("love:resize",function(w,h) --Do some calculations
    _HOST_W, _HOST_H = w, h
    local TSX, TSY = w/_LIKO_W, h/_LIKO_H --TestScaleX, TestScaleY
    if TSX < TSY then
      _LIKOScale = TSX
    else
      _LIKOScale = TSY
    end
    if _PixelPerfect then _LIKOScale = math.floor(_LIKOScale) end
    _LIKO_X, _LIKO_Y = (_HOST_W-_LIKO_W*_LIKOScale)/2, (_HOST_H-_LIKO_H*_LIKOScale)/2
    if _Mobile or config._Mobile then
      _LIKO_Y, _AlwaysDrawTimer = 0, 1
    end
    _ShouldDraw = true
  end)
  
  --Hook to some functions to redraw (when the window is moved, got focus, etc ...)
  events:register("love:focus",function(f) if f then _ShouldDraw = true end end) --Window got focus.
  events:register("love:visible",function(v) if v then _ShouldDraw = true end end) --Window got visible.
  
  --Initialize the gpu--
  if not love.filesystem.getInfo("Shaders","directory") then
    love.filesystem.createDirectory("Shaders")
  end
  
  local _ActiveShaderID = 0
  local _ActiveShaderName = "None"
  local _ActiveShader
  local _PostShaderTimer
  
  love.graphics.setDefaultFilter("nearest","nearest") --Set the scaling filter to the nearest pixel.
  
  local _CanvasFormats = love.graphics.getCanvasFormats()
  
  local _ScreenCanvas = love.graphics.newCanvas(_LIKO_W, _LIKO_H,{
    format = (_CanvasFormats.r8 and "r8" or "normal"),
    dpiscale = 1
  }) --Create the screen canvas.

  local _BackBuffer = love.graphics.newCanvas(_LIKO_W, _LIKO_H,{dpiscale=1}) --BackBuffer for post shaders.
  
  local _GIFCanvas = love.graphics.newCanvas(_LIKO_W*_GIFScale,_LIKO_H*_GIFScale,{
    format = (_CanvasFormats.r8 and "r8" or "normal"),
    dpiscale = 1
  }) --Create the gif canvas, used to apply the gif scale factor.

  local _Font = love.graphics.newImageFont(_FontPath, _FontChars, _FontExtraSpacing) --Create the default liko12 font.
  
  local gpuName, gpuVersion, gpuVendor, gpuDevice = love.graphics.getRendererInfo() --Used to apply some device specific bugfixes.
  if not love.filesystem.getInfo("/GPUInfo.txt","file") then love.filesystem.write("/GPUInfo.txt",gpuName..";"..gpuVersion..";"..gpuVendor..";"..gpuDevice) end
  if not love.filesystem.getInfo("/GPUCanvasFormats.txt","file") then
    local formats = {}
    for k,v in pairs(_CanvasFormats) do
      if v then table.insert(formats,k) end
    end
    table.sort(formats)
    formats = table.concat(formats,"\n")
    local rformats = {}
    for k,v in pairs(love.graphics.getCanvasFormats(true)) do
      if v then table.insert(rformats,k) end
    end
    table.sort(rformats)
    rformats = table.concat(rformats,"\n")
    love.filesystem.write("/GPUCanvasFormats.txt",formats.."\n\nReadable:\n\n"..rformats)
  end
  
  local calibVersion,ofs = 1.4
  if love.filesystem.getInfo("GPUCalibration.json","file") then
    ofs = json:decode(love.filesystem.read("/GPUCalibration.json"))
    if ofs.version < calibVersion then --Redo calibration
      ofs = love.filesystem.load(perpath.."calibrate.lua")()
      ofs.version = calibVersion
      love.filesystem.write("/GPUCalibration.json",json:encode_pretty(ofs))
    end
  else
    ofs = love.filesystem.load(perpath.."calibrate.lua")()
    ofs.version = calibVersion
    love.filesystem.write("/GPUCalibration.json",json:encode_pretty(ofs))
  end
  
  if gpuVersion == "OpenGL ES 3.1 v1.r7p0-03rel0.b8759509ece0e6dda5325cb53763bcf0" then
    --GPU glitch fix for this driver, happens at my samsung j700h
    ofs.screen = {0,-1}
  end
  
  love.graphics.clear(0,0,0,1) --Clear the host screen.
  
  love.graphics.setCanvas{_ScreenCanvas,stencil=true} --Activate LIKO12 canvas.
  love.graphics.clear(0,0,0,1) --Clear LIKO12 screen for the first time.
  
  events:trigger("love:resize", _HOST_W, _HOST_H) --Calculate LIKO12 scale to the host window for the first time.
  
  love.graphics.setFont(_Font) --Activate the default font.
  
  --Post initialization (Setup the in liko12 gpu settings)--
  
  local _DrawPalette = {} --The palette mapping for all drawing opereations except image:draw (p = 1).
  local _ImagePalette = {} --The palette mapping for image:draw opereations (p = 2).
  local _ImageTransparent = {} --The transparent colors palette, 1 for solid, 0 for transparent.
  local _DisplayPalette = {} --The final display shader palette, converts the red pixel values to a palette color.
  
  --Build the default palettes.
  for i=1,16 do
    _ImageTransparent[i] = (i==1 and 0 or 1) --Black is transparent by default.
    _DrawPalette[i] = i-1
    _ImagePalette[i] = i-1
    _DisplayPalette[i] = _ColorSet[i-1]
  end
  _DisplayPalette[17] = {0,0,0,0} --A bug in unpack ???
  _DrawPalette[17] = 0
  _ImagePalette[17] = 0
  _ImageTransparent[17] = 0
  
  local _Shaders = love.filesystem.load(perpath.."shaders.lua")()
  
  --Note: Those are modified version of picolove shaders.
  --The draw palette shader
  local _DrawShader = _Shaders.drawShader
  _DrawShader:send('palette', unpack(_DrawPalette)) --Upload the initial palette.
  
  --The image:draw palette shader
  local _ImageShader = _Shaders.imageShader
  _ImageShader:send('palette', unpack(_ImagePalette)) --Upload the inital palette.
  _ImageShader:send('transparent', unpack(_ImageTransparent)) --Upload the initial palette.
  
  --The final display shader.
  local _DisplayShader = _Shaders.displayShader
  _DisplayShader:send('palette', unpack(_DisplayPalette)) --Upload the colorset.
  
  --The pattern fill shader
  local _StencilShader = _Shaders.stencilShader
  
  love.graphics.setShader(_DrawShader) --Activate the drawing shader.
  
  --Internal Functions--
  local function _HostToLiko(x,y) --Convert a position from HOST screen to LIKO12 screen.
    --x, y = x-_ScreenX, y-_ScreenY
    return math.floor((x - _LIKO_X)/_LIKOScale), math.floor((y - _LIKO_Y)/_LIKOScale)
  end
  
  local function _LikoToHost(x,y) --Convert a position from LIKO12 screen to HOST
    return math.floor(x*_LIKOScale + _LIKO_X), math.floor(y*_LIKOScale + _LIKO_Y)
  end
  
  local function _GetColor(c) return _ColorSet[c or 0] or _ColorSet[0] end --Get the (rgba) table of a color id.
  
  local _ColorSetLookup = {}
  for k,v in ipairs(_ColorSet) do _ColorSetLookup[table.concat(v)] = k end
  local function _GetColorID(...) --Get the color id by the (rgba) table.
    local col = {...}
    if col[4] == 0 then return 0 end
    return _ColorSetLookup[table.concat(col)] or 0
  end
  
  --Apply transparent colors effect on LIKO12 Images when encoded to PNG
  local function _EncodeTransparent(x,y, r,g,b,a)
    if _ImageTransparent[floor(r*255)+1] == 0 then return 0,0,0,0 end
    return r,g,b,a
  end
  
  --Convert from LIKO12 palette to real colors.
  local function _ExportImage(x,y, r,g,b,a)
    r = floor(r*255)
    if _ImageTransparent[r+1] == 0 then return 0,0,0,0 end
    return colorTo1(_ColorSet[r])
  end
  
  --Convert from LIKO-12 palette to real colors ignoring transparent colors.
  local function _ExportImageOpaque(x,y, r,g,b,a)
    return colorTo1(_ColorSet[floor(r*255)])
  end
  
  local LastMSG = "" --Last system message.
  local LastMSGTColor = 4 --Last system message text color.
  local LastMSGColor = 9 --Last system message color.
  local LastMSGGif = false --Show Last system message in the gif recording ?
  local MSGTimer = 0 --The message timer.
  
  local function systemMessage(msg,time,tcol,col,hideInGif)
    if type(msg) ~= "string" then return false, "Message must be a string, provided: "..type(msg) end
    
    if time and type(time) ~= "number" then return false, "Time must be a number or a nil, provided: "..type(time) end
    if tcol and type(tcol) ~= "number" then return false, "Text color must be a number or a nil, provided: "..type(tcol) end
    if col and type(col) ~= "number" then return false, "Body Color must be a number or a nil, provided: "..type(col) end
    local time, tcol, col = time or 1, math.floor(tcol or 4), math.floor(col or 9)
    if time <= 0 then return false, "Time must be bigger than 0" end
    if tcol < 0 or tcol > 15 then return false, "Text Color ID out of range ("..tcol..") Must be [0,15]" end
    if col < 0 or col > 15 then return false, "Body Color ID out of range ("..col..") Must be [0,15]" end
    LastMSG = msg
    LastMSGTColor = tcol
    LastMSGColor = col
    LastMSGGif = not hideInGif
    MSGTimer = time
    
    return true
  end
  
  --Convert from real colors to LIKO-12 palette
  local function _ImportImage(x,y, r,g,b,a)
    return _GetColorID(colorTo255(r,g,b,a))/255,0,0,1
  end
  
  --GifRecorder
  local _GIF = love.filesystem.load(perpath.."gif.lua")( _GIFScale, _LIKO_W, _LIKO_H ) --Load the gif library
  
  local function startGifRecording()
    if _GIFRec then return end --If there is an already in progress gif
    if love.filesystem.getInfo("/~gifrec.gif","file") then
      _GIFRec = _GIF.continue("/~gifrec.gif")
      _GIFPStart = love.filesystem.read("/~gifrec.pal")
      _GIFPChanged = true --To check if it's the same palette
      _GIFPal = false
      systemMessage("Resumed gif recording",1,false,false,true)
      return
    end
    _GIFRec = _GIF.new("/~gifrec.gif",_ColorSet)
    _GIFPChanged = false
    _GIFPStart = ""
    for i=0,15 do
      local p = _ColorSet[i]
      _GIFPStart = _GIFPStart .. string.char(p[1],p[2],p[3])
    end
    _GIFPal = false
    love.filesystem.write("/~gifrec.pal",_GIFPStart)
    systemMessage("Started gif recording",1,false,false,true)
  end
  
  local function pauseGifRecording()
    if not _GIFRec then return end
    _GIFRec.file:flush()
    _GIFRec.file:close()
    _GIFRec = nil
    systemMessage("Paused gif recording",1,false,false,true)
  end
  
  local function endGifRecording()
    if not _GIFRec then
      if love.filesystem.getInfo("/~gifrec.gif","file") then
        _GIFRec = _GIF.continue("/~gifrec.gif")
      else return end
      systemMessage("Saved old gif recording successfully",2,false,false,true)
    else
      systemMessage("Saved gif recording successfully",2,false,false,true)
    end
    _GIFRec:close()
    _GIFRec = nil
    love.filesystem.write("/LIKO12-"..os.time()..".gif",love.filesystem.read("/~gifrec.gif"))
    love.filesystem.remove("/~gifrec.gif")
    love.filesystem.remove("/~gifrec.pal")
  end
  
  --To handle gif control buttons
  events:register("love:keypressed", function(key,sc,isrepeat)
    if love.keyboard.isDown("lshift","rshift") then return end
    if key == _GIFStartKey then
      startGifRecording()
    elseif key == _GIFEndKey then
      endGifRecording()
    elseif key == _GIFPauseKey then
      pauseGifRecording()
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
  if love.filesystem.getInfo("/~gifreboot.gif","file") then
    if not _GIFRec then
      love.filesystem.write("/~gifrec.gif",love.filesystem.read("/~gifreboot.gif"))
      love.filesystem.remove("/~gifreboot.gif")
      _GIFRec = _GIF.continue("/~gifrec.gif")
    end
  end
  
  local _GrappedCursor = false --If the cursor must be drawed by the GPU (not using a system cursor)
  local _Cursor = "none"
  local _CursorsCache = {}
  
  --Handle post-shader switching
  events:register("love:keypressed", function(key,sc,isrepeat)
    if not love.keyboard.isDown("lshift","rshift") then return end
    if key ~= _GIFStartKey and key ~= _GIFEndKey and key ~= _GIFPauseKey then return end
    local shaderslist = love.filesystem.getDirectoryItems("/Shaders/")
    if key == _GIFEndKey then --Next Shader
      local nextShader = shaderslist[_ActiveShaderID + 1]
      if nextShader and love.filesystem.getInfo("/Shaders/"..nextShader,"file") then
        local ok, shader = pcall(love.graphics.newShader,"/Shaders/"..nextShader)
        if not ok then
          print("Failed to load shader",nextShader)
          shader = nil
        end
        
        _ActiveShaderID = _ActiveShaderID + 1
        _ActiveShaderName = nextShader
        _ActiveShader = shader
        _PostShaderTimer = nil
        
        if _ActiveShader then
          local warnings = _ActiveShader:getWarnings()
          if warnings ~= "vertex shader:\npixel shader:\n" then
            print("Shader Warnings:")
            print(warnings)
          end
          
          if _ActiveShader:hasUniform("time") then
            _PostShaderTimer = 0
          end
        else
          love.mouse.setVisible(not _GrappedCursor)
        end
      else
        _ActiveShaderID = 0
        _ActiveShaderName = "None"
        _ActiveShader = nil
        _PostShaderTimer = nil
        love.mouse.setVisible(not _GrappedCursor)
      end
    elseif key == _GIFStartKey then --Prev Shader
      local nextID = _ActiveShaderID - 1; if nextID < 0 then nextID = #shaderslist end
      local nextShader = shaderslist[nextID]
      if nextShader and love.filesystem.getInfo("/Shaders/"..nextShader,"file") then
        local ok, shader = pcall(love.graphics.newShader,"/Shaders/"..nextShader)
        if not ok then
          print("Failed to load shader",nextShader)
          print(shader)
          shader = nil
        end
        
        _ActiveShaderID = nextID
        _ActiveShaderName = nextShader
        _ActiveShader = shader
        _PostShaderTimer = nil
        
        if _ActiveShader then
          local warnings = _ActiveShader:getWarnings()
          if warnings ~= "vertex shader:\npixel shader:\n" then
            print("Shader Warnings:")
            print(warnings)
          end
          
          if _ActiveShader:hasUniform("time") then
            _PostShaderTimer = 0
          end
        else
          love.mouse.setVisible(not _GrappedCursor)
        end
      else
        _ActiveShaderID = 0
        _ActiveShaderName = "None"
        _ActiveShader = nil
        _PostShaderTimer = nil
        love.mouse.setVisible(not _GrappedCursor)
      end
    elseif key == _GIFPauseKey then --None Shader
      _ActiveShaderID = 0
      _ActiveShaderName = "None"
      _ActiveShader = nil
      _PostShaderTimer = nil
      love.mouse.setVisible(not _GrappedCursor)
    end
    
    systemMessage("Shader: ".._ActiveShaderName,2,false,false,true)
  end)

  --Post-Shader Time value
  events:register("love:update",function(dt)
    if _PostShaderTimer then
      _PostShaderTimer = (_PostShaderTimer + dt)%10
    end
  end)
  
  --File drop hook
  events:register("love:filedropped", function(file)
    file:open("r")
    local data = file:read()
    file:close()
    if cpukit then cpukit.triggerEvent("filedropped",file:getFilename(),data) end
  end)
  
  --Mouse Hooks (To translate them to LIKO12 screen)--
  events:register("love:mousepressed",function(x,y,b,istouch)
    local x,y = _HostToLiko(x,y)
    events:trigger("GPU:mousepressed",x,y,b,istouch)
    if cpukit then cpukit.triggerEvent("mousepressed",x,y,b,istouch) end
  end)
  events:register("love:mousemoved",function(x,y,dx,dy,istouch)
    local x,y = _HostToLiko(x,y)
    local dx, dy = dx/_LIKOScale, dy/_LIKOScale
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
    local dx, dy = dx/_LIKOScale, dy/_LIKOScale
    events:trigger("GPU:touchpressed",id,x,y,dx,dy,p)
    if cpukit then cpukit.triggerEvent("touchpressed",id,x,y,dx,dy,p) end
  end)
  events:register("love:touchmoved",function(id,x,y,dx,dy,p)
    local x,y = _HostToLiko(x,y)
    local dx, dy = dx/_LIKOScale, dy/_LIKOScale
    events:trigger("GPU:touchmoved",id,x,y,dx,dy,p)
    if cpukit then cpukit.triggerEvent("touchmoved",id,x,y,dx,dy,p) end
  end)
  events:register("love:touchreleased",function(id,x,y,dx,dy,p)
    local x,y = _HostToLiko(x,y)
    local dx, dy = dx/_LIKOScale, dy/_LIKOScale
    events:trigger("GPU:touchreleased",id,x,y,dx,dy,p)
    if cpukit then cpukit.triggerEvent("touchreleased",id,x,y,dx,dy,p) end
  end)

  local GPU, yGPU = {}, {}
  
  local newImageHandler = love.filesystem.load(perpath.."imageHandler.lua")
  
  --Video-Ram
  
  local VRAMBound = false
  local VRAMImg
  
  local function BindVRAM()
    if VRAMBound then return end
    love.graphics.setCanvas()
    VRAMImg = _ScreenCanvas:newImageData()
    love.graphics.setCanvas{_ScreenCanvas,stencil=true}
    VRAMBound = true
  end
  
  local function UnbindVRAM(keepbind)
    if not VRAMBound then return end
    local Img = love.graphics.newImage(VRAMImg)
    GPU.pushColor()
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader()
    love.graphics.clear(0,0,0,1)
    love.graphics.draw(Img,ofs.image[1],ofs.image[2])
    love.graphics.setShader(_DrawShader)
    love.graphics.pop()
    GPU.popColor()
    if not keepbind then
      VRAMBound = false
      VRAMImg = nil
    end
  end
  
  local VRAMHandler; VRAMHandler = newImageHandler(_LIKO_W,_LIKO_H,function()
    _ShouldDraw = true
  end,function()
    BindVRAM()
    VRAMHandler("setImage",0,0,VRAMImg)
  end)

  --LabelImage - Handler
  local LabelImage = love.image.newImageData(_LIKO_W, _LIKO_H)
  
  LabelImage:mapPixel(function() return 0,0,0,1 end)
  
  local LIMGHandler; LIMGHandler = newImageHandler(_LIKO_W,_LIKO_H,function() end,function() end)
  
  LIMGHandler("setImage",0,0,LabelImage)
  
  --The api starts here--
  
  local flip = false --Is the code waiting for the screen to draw, used to resume the coroutine.
  local Clip = false --The current active clipping region.
  local ColorStack = {} --The colors stack (pushColor,popColor)
  local PaletteStack = {} --The palette stack (pushPalette,popPalette)
  local printCursor = {x=0,y=0,bgc=0} --The print grid cursor pos.
  local TERM_W, TERM_H = math.floor(_LIKO_W/(_FontW+1)), math.floor(_LIKO_H/(_FontH+2)) --The size of characters that the screen can fit.
  local PatternFill --The pattern stencil function
  
  local _PasteImage --A walkthrough to avoide exporting the image to png and reloading it.
  
  local function Verify(value,name,etype,allowNil)
    if type(value) ~= etype then
      if allowNil then
        error(name.." should be a "..etype.." or a nil, provided: "..type(value),3)
      else
        error(name.." should be a "..etype..", provided: "..type(value),3)
      end
    end
    
    if etype == "number" then
      return math.floor(value)
    end
  end
  
  --Those explains themselves.
  function GPU.screenSize() return _LIKO_W, _LIKO_H end
  function GPU.screenWidth() return _LIKO_W end
  function GPU.screenHeight() return _LIKO_H end
  function GPU.termSize() return TERM_W, TERM_H end
  function GPU.termWidth() return TERM_W end
  function GPU.termHeight() return TERM_H end
  function GPU.fontSize() return _FontW, _FontH end
  function GPU.fontWidth() return _FontW end
  function GPU.fontHeight() return _FontH end
  
  function GPU.colorPalette(id,r,g,b)
    if not (id or r or g or b) then --Reset
      for i=0,15 do
        local r,g,b = unpack(_DefaultColorSet[i])
        _ColorSet[i] = {r,g,b,255}
        _DisplayPalette[i+1] = _ColorSet[i]
      end
      _DisplayShader:send('palette', unpack(_DisplayPalette)) --Upload the new colorset.
      _ShouldDraw = true
      _GIFPChanged = true
      return
    end
    
    id = Verify(id,"Color ID","number")
    if not _ColorSet[id] then return error("Color ID out of range ("..id..") Must be [0,15]") end
    
    if r or g or b then
      local r,g,b = r or _ColorSet[id][1], g or _ColorSet[id][2], b or _ColorSet[id][3]
      r = Verify(r,"Red value","number")
      g = Verify(g,"Green value","number")
      b = Verify(b,"Blue value","number")
      if r < 0 or r > 255 then return error("Red value out of range ("..r..") Must be [0,255]") end
      if g < 0 or g > 255 then return error("Green value out of range ("..g..") Must be [0,255]") end
      if b < 0 or b > 255 then return error("Blue value out of range ("..b..") Must be [0,255]") end
      _ColorSet[id] = {r,g,b,255}
      _DisplayPalette[id+1] = _ColorSet[id]
      _DisplayShader:send('palette', unpack(_DisplayPalette)) --Upload the new colorset.
      _ShouldDraw = true
      _GIFPChanged = true
    else
      return unpack(_ColorSet[id])
    end
  end
  
  --Call with color id to set the active color.
  --Call with no args to get the current acive color id.
  function GPU.color(id)
    if id then
      id = Verify(id,"The color id","number")
      if id > 15 or id < 0 then return error("The color id is out of range ("..id..") Must be [0,15]") end --Error
      love.graphics.setColor(id/255,0,0,1) --Set the active color.
    else
      local r,g,b,a = getColor()
      return r --Return the current color.
    end
  end
  
  --Push the current active color to the ColorStack.
  function GPU.pushColor()
    table.insert(ColorStack,GPU.color()) --Add the active color id to the stack.
  end
  
  --Pop the last color from the ColorStack and set it to the active color.
  function GPU.popColor()
    if #ColorStack == 0 then return error("No more colors to pop.") end --Error
    GPU.color(ColorStack[#ColorStack]) --Set the last color in the stack to be the active color.
    table.remove(ColorStack,#ColorStack) --Remove the last color in the stack.
  end
  
  --Map pallete colors
  function GPU.pal(c0,c1,p)
    local drawchange = false  --Has any changes been made to the draw palette (p=1).
    local imagechange = false  --Has any changes been made to the image:draw palette (p=2).
    
    --Error check all the arguments.
    if c0 then c0 = Verify(c0, "C0","number",true) end
    if c1 then c1 = Verify(c1, "C1","number",true) end
    if p then p = Verify(p, "P","number",true) end
    if c0 and (c0 < 0 or c0 > 15) then return error("C0 is out of range ("..c0..") expected [0,15]") end
    if c1 and (c1 < 0 or c1 > 15) then return error("C1 is out of range ("..c1..") expected [0,15]") end
    if p and (p < 0 or p > 1) then return error("P is out of range ("..p..") expected [0,1]") end
    
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
      if ((not p) or p == 0) and _DrawPalette[c0+1] ~= c0 then
        drawchange = true
        _DrawPalette[c0+1] = c0
      end
      
      if ((not p) or p > 0) and _ImagePalette[c0+1] ~= c0 then
        imagechange = true
        _ImagePalette[c0+1] = c0
      end
    --Modify the palette
    elseif c0 and c1 then
      if ((not p) or p == 0) and _DrawPalette[c0+1] ~= c1 then
        drawchange = true
        _DrawPalette[c0+1] = c1
      end
      
      if ((not p) or p > 0) and _ImagePalette[c0+1] ~= c1 then
        imagechange = true
        _ImagePalette[c0+1] = c1
      end
    end
    --If changes has been made then upload the data to the shaders.
    if drawchange then _DrawShader:send('palette',unpack(_DrawPalette)) end
    if imagechange then _ImageShader:send('palette',unpack(_ImagePalette)) end
  end
  
  function GPU.palt(c,t)
    local changed = false
    if c then
      c = Verify(c,"Color","number")
      if (c < 0 or c > 15) then return error("Color out of range ("..c..") expected [0,15]") end
      
      if _ImageTransparent[c+1] == (t and 1 or 0) then
        _ImageTransparent[c+1] = (t and 0 or 1)
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
  end
  
  function GPU.popPalette()
    if #PaletteStack == 0 then return error("No more palettes to pop.") end --Error
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
  end
  
  --Check the flip flag and clear it
  function GPU._hasFlipped()
    if _Flipped then
      _Flipped = false
      return true
    end
    
    return false
  end
  
  --Suspend the coroutine till the screen is updated
  function yGPU.flip()
    UnbindVRAM() _ShouldDraw = true -- Incase if no changes are made so doesn't suspend forever
    flip = true
    return 2 --Do not resume automatically
  end
  
  --Camera Functions
  function GPU.cam(mode,a,b)
    if mode then Verify(mode,"Mode","string") end
    if a then Verify(a,"a","number",true) end
    if b then Verify(b,"b","number",true) end
    
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
        return error("Unknown mode: "..mode)
      end
    else
      GPU.pushColor()
      love.graphics.origin()
      GPU.popColor()
    end
  end
  
  local MatrixStack = 0
  
  function GPU.clearMatrixStack()
    for i=1, MatrixStack do
      love.graphics.pop()
    end
    
    MatrixStack = 0
  end
  
  function GPU.pushMatrix()
    if MatrixStack == 256 then
      return error("Maximum stack depth reached, More pushes than pops ?")
    end
    MatrixStack = MatrixStack + 1
    local ok, err = pcall(love.graphics.push)
    if not ok then return error(err) end
  end
  
  function GPU.popMatrix()
    if MatrixStack == 0 then
      return error("The stack is empty, More pops than pushes ?")
    end
    MatrixStack = MatrixStack - 1
    local ok, err = pcall(love.graphics.pop)
    if not ok then return error(err) end
  end
  
  function GPU.patternFill(img)
    if img then
      Verify(img,"Pattern ImageData","table")
      if not img.typeOf or not img.typeOf("GPU.imageData") then return error("Invalid ImageData") end
      
      local IMG = love.image.newImageData(img:size())
      img:___pushimgdata()
      IMG:paste(_PasteImage,0,0)
      _PasteImage = nil
      
      IMG = love.graphics.newImage(IMG)
      
      local QUAD = img:quad(0,0,_LIKO_W,_LIKO_H)
      
      PatternFill = function()
        love.graphics.setShader(_StencilShader)
        
        love.graphics.draw(IMG, QUAD, 0,0)
        
        love.graphics.setShader(_DrawShader)
      end
      
      love.graphics.stencil(PatternFill, "replace", 1)
      love.graphics.setStencilTest("greater",0)
    else
      PatternFill = nil
      love.graphics.setStencilTest()
    end
  end
  
  function GPU.clip(x,y,w,h)
    local x,y,w,h = x,y,w,h
    if x then
      if type(x) == "table" then
        x,y,w,h = unpack(x)
      end
      
      Verify(x,"X","number")
      Verify(y,"Y","number")
      Verify(w,"W","number")
      Verify(h,"H","number")
      
      Clip = {x,y,w,h}
      love.graphics.setScissor(unpack(Clip))
    else
      local oldClip = Clip
      Clip = false
      love.graphics.setScissor()
      
      return Clip
    end
    return true
  end
  
  --Draw a rectangle filled, or lines only.
  --X pos, Y pos, W width, H height, L linerect, C colorid.
  function GPU.rect(x,y,w,h,l,c) UnbindVRAM()
    local x,y,w,h,l,c = x, y, w, h, l or false, c --In case if they are not provided.
    
    --It accepts all the args as a table.
    if type(x) == "table" then
      x,y,w,h,l,c = unpack(x)
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
    
    love.graphics.rectangle(l and "line" or "fill",x,y,w,h) _ShouldDraw = true --Draw and tell that changes has been made.
    
    if c then GPU.popColor() end --Restore the color from the stack.
  end
  
  --Draws a circle filled, or lines only.
  function GPU.circle(x,y,r,l,c,s) UnbindVRAM()
    local x,y,r,l,c,s = x, y, r, l or false, c, s --In case if they are not provided.
    
    --It accepts all the args as a table.
    if x and type(x) == "table" then
      x,y,r,l,c,s = unpack(x)
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
    
    love.graphics.circle(l and "line" or "fill",x,y,r,s) _ShouldDraw = true --Draw and tell that changes has been made.
    
    if c then GPU.popColor() end --Restore the color from the stack.
  end
  
  --Draws a triangle
  function GPU.triangle(x1,y1,x2,y2,x3,y3,l,col) UnbindVRAM()
    local x1,y1,x2,y2,x3,y3,l,col = x1,y1,x2,y2,x3,y3,l or false,col --Localize them
    
    if type(x1) == "table" then
      x1,y1,x2,y2,x3,y3,l,col = unpack(x1)
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
    
    love.graphics.polygon(l and "line" or "fill", x1,y1,x2,y2,x3,y3)
    
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
    love.graphics.polygon("fill",unpack(args)) _ShouldDraw = true --Draw the lines and tell that changes has been made.
    GPU.popColor() --Pop the last color in the stack.
  end
  
  --Draws a ellipse filled, or lines only.
  function GPU.ellipse(x,y,rx,ry,l,c,s) UnbindVRAM()
    local x,y,rx,ry,l,c,s = x or 0, y or 0, rx or 1, ry or 1, l or false, c, s --In case if they are not provided.
    
    --It accepts all the args as a table.
    if x and type(x) == "table" then
      x,y,rx,ry,l,c,s = unpack(x)
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
    
    love.graphics.ellipse(l and "line" or "fill",x,y,rx,ry,s) _ShouldDraw = true --Draw and tell that changes has been made.
    
    if c then GPU.popColor() end --Restore the color from the stack.
  end
  
  --Sets the position of the printing corsor when x,y are supplied
  --Or returns the current position of the printing cursor when x,y are not supplied
  function GPU.printCursor(x,y,bgc)
    if x or y or bgc then
      local x, y = x or printCursor.x, y or printCursor.y
      local bgc = bgc or printCursor.bgc
      
      x = Verify(x,"X coord","number",true)
      y = Verify(y,"Y coord","number",true)
      bgc = Verify(bgc,"Background Color","number",true)
      
      printCursor.x, printCursor.y = x, y --Set the cursor pos
      printCursor.bgc = bgc
    else
      return printCursor.x, printCursor.y, printCursor.bgc --Return the current cursor pos
    end
  end
  
  --Prints text to the screen,
  --Acts as a terminal print if x, y are not provided,
  --Or prints at the specific pos x, y
  function GPU.print(t,x,y,limit,align,r,sx,sy,ox,oy,kx,ky) UnbindVRAM()
    local t = tostring(t) --Make sure it's a string
    if x and y then --Print at a specific position on the screen
      --Error handelling
      x = Verify(x,"X coord","number")
      y = Verify(y,"Y coord","number")
      if limit then limit = Verify(limit,"Line limit","number",true) end
      if align then
        Verify(align,"Align","string",true)
        if align ~= "left" and align ~= "center" and align ~= "right" and align ~= "justify" then
          return error("Invalid line alignment '"..align.."' !")
        end
      end
      if r then Verify(r,"Rotation","number",true) end
      if sx then Verify(sx,"X Scale factor","number",true) end
      if sy then Verify(sy,"Y Scale factor","number",true) end
      if ox then Verify(ox,"X Origin offset","number",true) end
      if oy then Verify(oy,"Y Origin offset","number",true) end
      if kx then Verify(kx,"X Shearing factor","number",true) end
      if ky then Verify(ky,"Y Shearing factor","number",true) end
      
      --Print to the screen
      if limit then --Wrapped
        love.graphics.printf(t,x+ofs.print[1],y+ofs.print[2],limit,align,r,sx,sy,ox,oy,kx,ky) _ShouldDraw = true
      else
        love.graphics.print(t,x+ofs.print[1],y+ofs.print[2],r,sx,sy,ox,oy,kx,ky) _ShouldDraw = true
      end
    else --Print to terminal pos
      local pc = printCursor --Shortcut
      
      local function togrid(gx,gy) --Covert to grid cordinates
        return math.floor(gx*(_FontW+1)), math.floor(gy*(_FontH+2))
      end
      
      --A function to draw the background rectangle
      local function drawbackground(gx,gy,gw)
        if pc.bgc == -1 or gw < 1 then return end --No need to draw the background
        gx,gy = togrid(gx,gy)
        GPU.rect(gx,gy, gw*(_FontW+1)+1,_FontH+3, false, pc.bgc)
      end
      
      --Draw directly without formatting nor updating the cursor pos.
      if y then
        drawbackground(pc.x, pc.y, t:len()) --Draw the background.
        local gx,gy = togrid(pc.x, pc.y)
        love.graphics.print(t,gx+1+ofs.print_grid[1],gy+1+ofs.print_grid[2]) --Print the text.
        pc.x = pc.x + t:len() --Update the x pos
        return true --It ran successfully
      end
      t = t.."\n"
      if type(x) == "nil" or x then t = t .. "\n" end --Auto newline after printing.
      
      local sw, sh = TERM_W*(_FontW+1), TERM_H*(_FontH+2) --Screen size
      local pre_spaces = string.rep(" ", pc.x) --The pre space for text wrapping to calculate
      local maxWidth, wrappedText = _Font:getWrap(pre_spaces..t, sw) --Get the text wrapped
      local linesNum = #wrappedText --Number of lines
      if linesNum > TERM_H-pc.y then --It will go down of the screen, so shift the screen up.
        GPU.pushPalette() GPU.palt() GPU.pal() --Backup the palette and reset the palette.
        local extra = linesNum - (TERM_H-pc.y) --The extra lines that will draw out of the screen.
        local sc = GPU.screenshot() --Take a screenshot
        GPU.clear(0) --Clear the screen
        sc:image():draw(0, -extra*(_FontH+2)) --Draw the screen shifted up
        pc.y = pc.y-extra --Update the cursor pos.
        GPU.popPalette() --Restore the palette.
      end
      
      local drawY = pc.y
      
      --Iterate over the lines.
      for k, line in ipairs(wrappedText) do
        local printX = 0
        if k == 1 then line = line:sub(pre_spaces:len()+1,-1); printX = pc.x end --Remove the pre_spaces
        local linelen = line:len() --The line length
        drawbackground(printX,pc.y,linelen) --Draw the line background
        
        --Update the cursor pos
        pc.x = printX + line:len()
        if wrappedText[k+1] then pc.y = pc.y + 1 end --If there's a next line
      end
      
      love.graphics.printf(pre_spaces..t,1+ofs.print_grid[1],drawY*(_FontH+2)+1+ofs.print_grid[2],sw) _ShouldDraw = true --Print the text
    end
  end
  
  function GPU.wrapText(text,sw)
    local args = {pcall(_Font.getWrap,_Font,text, sw)}
    if args[1] then
      return select(2,unpack(args))
    else
      return error(tostring(args[2]))
    end
  end
  
  function GPU.printBackspace(c,skpCr) UnbindVRAM()
    local c = c or printCursor.bgc
    c = Verify(c,"Color","number",true)
    local function cr() local s = GPU.screenshot():image() GPU.clear() s:draw(1,_FontH+2) end
    
    local function togrid(gx,gy) --Covert to grid cordinates
      return math.floor(gx*(_FontW+1)), math.floor(gy*(_FontH+2))
    end
    
    --A function to draw the background rectangle
    local function drawbackground(gx,gy,gw)
      if c == -1 or gw < 1 then return end --No need to draw the background
      gx,gy = togrid(gx,gy)
      GPU.rect(gx,gy, gw*(_FontW+1)+1,_FontH+3, false, c)
    end
      
    if printCursor.x > 0 then
      printCursor.x = printCursor.x-1
      drawbackground(printCursor.x,printCursor.y,1)
    elseif not skpCr then
      if printCursor.y > 0 then
        printCursor.y = printCursor.y - 1
        printCursor.x = TERM_W-1
      else
        printCursor.x = TERM_W-1
        cr()
      end
      drawbackground(printCursor.x,printCursor.y,1)
    end
  end
  
  --Clears the whole screen with black or the given color id.
  function GPU.clear(c) UnbindVRAM()
    local c = c or 0
    c = Verify(c,"The color id","number",true)
    if c > 15 or c < 0 then return error("The color id is out of range.") end --Error
    love.graphics.clear(c/255,0,0,1) _ShouldDraw = true
  end
  
  --Draws a point/s at specific location/s, accepts the colorid as the last args, x and y of points must be provided before the colorid.
  function GPU.points(...) UnbindVRAM()
    local args = {...} --The table of args
    GPU.pushColor() --Push the current color.
    if not (#args % 2 == 0) then GPU.color(args[#args]) table.remove(args,#args) end --Extract the colorid (if exists) from the args and apply it.
    for k,v in ipairs(args) do Verify(v,"Arg #"..k,"number") end --Error
    for k,v in ipairs(args) do if (k % 2 == 1) then args[k] = v + ofs.point[1] else args[k] = v + ofs.point[2] end end --Apply the offset.
    love.graphics.points(unpack(args)) _ShouldDraw = true --Draw the points and tell that changes has been made.
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
    love.graphics.line(unpack(args)) _ShouldDraw = true --Draw the lines and tell that changes has been made.
    GPU.popColor() --Pop the last color in the stack.
  end
  GPU.line = GPU.lines --Just an alt name :P.
  
  --Image API--
  function GPU.quad(x,y,w,h,sw,sh)
    local ok, err = pcall(love.graphics.newQuad,x,y,w,h,sw,sh)
    if ok then
      return err
    else
      return error(err)
    end
  end
  
  function GPU.image(data)
    local Image, SourceData
    if type(data) == "string" then --Load liko12 specialized image format
      local ok, imageData = pcall(GPU.imagedata,data)
      if not ok then return error(imageData) end
      return imageData:image()
    elseif type(data) == "userdata" and data.typeOf and data:typeOf("ImageData") then
      local ok, err = pcall(love.graphics.newImage,data)
      if not ok then return error("Invalid image data") end
      Image = err
      Image:setWrap("repeat")
      SourceData = data
    end
    
    local i = {}
    
    function i:draw(x,y,r,sx,sy,quad) UnbindVRAM()
      local x, y, r, sx, sy = x or 0, y or 0, r or 0, sx or 1, sy or 1
      GPU.pushColor()
      love.graphics.setShader(_ImageShader)
      love.graphics.setColor(1,1,1,1)
      if quad then
        love.graphics.draw(Image,quad,math.floor(x+ofs.quad[1]),math.floor(y+ofs.quad[2]),r,sx,sy)
      else
        love.graphics.draw(Image,math.floor(x+ofs.image[1]),math.floor(y+ofs.image[2]),r,sx,sy)
      end
      love.graphics.setShader(_DrawShader)
      GPU.popColor()
      _ShouldDraw = true
      return self
    end
    
    function i:refresh()
      Image:replacePixels(SourceData)
      return self
    end
    
    function i:size() return Image:getDimensions() end
    function i:width() return Image:getWidth() end
    function i:height() return Image:getHeight() end
    function i:data() return GPU.imagedata(SourceData) end
    function i:quad(x,y,w,h) return love.graphics.newQuad(x,y,w or self:width(),h or self:height(),self:width(),self:height()) end
    
    function i:type() return "GPU.image" end
    function i:typeOf(t) if t == "GPU" or t == "image" or t == "GPU.image" or t == "LK12" then return true end end
    
    return i
  end
  
  function GPU.imagedata(w,h)
    local imageData
    if h and tonumber(w) then
      imageData = love.image.newImageData(w,h)
      imageData:mapPixel(function() return 0,0,0,1 end)
    elseif type(w) == "string" then --Load specialized liko12 image format
      if w:sub(0,12) == "LK12;GPUIMG;" then
        w = w:gsub("\n","")
        local w,h,data = string.match(w,"LK12;GPUIMG;(%d+)x(%d+);(.+)")
        imageData = love.image.newImageData(w,h)
        local nextColor = string.gmatch(data,"%x")
        imageData:mapPixel(function(x,y,r,g,b,a)
          return tonumber(nextColor() or "0",16)/255,0,0,1
        end)
      else
        local ok, fdata = pcall(love.filesystem.newFileData,w,"image.png")
        if not ok then return error("Invalid image data") end
        local ok, img = pcall(love.image.newImageData,fdata)
        if not ok then return error("Invalid image data") end
        local ok, err = pcall(img.mapPixel,img,_ImportImage)
        if not ok then return error("Invalid image data") end
        imageData = img
      end
    elseif type(w) == "userdata" and w.typeOf and w:typeOf("ImageData") then
      imageData = w
    else
      return error("Invalid arguments")
    end
    
    local id = {}
    
    function id:size() return imageData:getDimensions() end
    function id:getPixel(x,y)
      if not x then return error("Must provide X") end
      if not y then return error("Must provide Y") end
      x,y = math.floor(x), math.floor(y)
      if x < 0 or x > self:width()-1 or y < 0 or y > self:height()-1 then
        return false, "Pixel position out from the image region"
      end
      local r,g,b,a = imageData:getPixel(x,y)
      return floor(r*255)
    end
    function id:setPixel(x,y,c)
      if type(c) ~= "number" then return error("Color must be a number, provided "..type(c)) end
      if not x then return error("Must provide X") end
      if not y then return error("Must provide Y") end
      x,y = math.floor(x), math.floor(y)
      if x < 0 or x > self:width()-1 or y < 0 or y > self:height()-1 then
        return false, "Pixel position out from the image region"
      end
      c = math.floor(c) if c < 0 or c > 15 then return error("Color out of range ("..c..") expected [0,15]") end
      imageData:setPixel(x,y,c/255,0,0,1)
      return self
    end
    function id:map(mf)
      imageData:mapPixel(
      function(x,y,r,g,b,a)
        local c = mf(x,y,floor(r*255))
        if c and type(c) ~= "number" then return error("Color must be a number, provided "..type(c)) elseif c then c = floor(c) end
        if c and (c < 0 or c > 15) then return error("Color out of range ("..c..") expected [0,15]") end
        if c then return c/255,0,0,1 else return r,g,b,a end
      end)
      return self
    end
    function id:height() return imageData:getHeight() end
    function id:width() return imageData:getWidth() end
    function id:___pushimgdata() _PasteImage = imageData end --An internal function used when pasting images.
    
    function id:paste(imgData,dx,dy,sx,sy,sw,sh)
      if type(imgData) ~= "table" then return error("ImageData must be a table, got '"..type(imageData).."'") end
      if not (imgData.typeOf and imgData.typeOf("GPU.imageData")) then return error("Invalid ImageData Object") end
      _PasteImage = false; imgData:___pushimgdata(); if not _PasteImage then return error("Fake ImageData Object") end
      imageData:paste(_PasteImage,dx or 0,dy or 0,sx or 0,sy or 0,sw or _PasteImage:getWidth(), sh or _PasteImage:getHeight())
      return self
    end
    
    function id:quad(x,y,w,h) return love.graphics.newQuad(x,y,w or self:width(),h or self:height(),self:width(),self:height()) end
    function id:image() return GPU.image(imageData) end
    
    function id:export()
      local expData = love.image.newImageData(self:width(),self:height())
      expData:mapPixel(function(x,y) return _ExportImage(x,y, imageData:getPixel(x,y)) end)
      return expData:encode("png"):getString()
    end
    
    function id:exportOpaque()
      local expData = love.image.newImageData(self:width(),self:height())
      expData:mapPixel(function(x,y) return _ExportImageOpaque(x,y, imageData:getPixel(x,y)) end)
      return expData:encode("png"):getString()
    end
    
    function id:enlarge(scale)
      local scale = math.floor(scale or 1)
      if scale <= 0 then scale = 1 end --Protection
      if scale == 1 then return self end
      local newData = GPU.imagedata(self:width()*scale,self:height()*scale)
      self:map(function(x,y,c)
        for iy=0, scale-1 do for ix=0, scale-1 do
          newData:setPixel(x*scale + ix,y*scale + iy,c)
        end end
      end)
      return newData
    end
    
    function id:encode() --Export to liko12 format
      local data = {strformat("LK12;GPUIMG;%dx%d;",self:width(),self:height())}
      local datalen = 2
      self:map(function(x,y,c)
        if x == 0 then
          data[datalen] = "\n"
          datalen = datalen + 1
        end
        data[datalen] = strformat("%X",c)
        datalen = datalen + 1
      end)
      return table.concat(data)
    end
    
    function id.type() return "GPU.imageData" end
    function id.typeOf(t) if t == "GPU" or t == "imageData" or t == "GPU.imageData" or t == "LK12" then return true end end
    
    return id
  end
  
  function GPU.screenshot(x,y,w,h)
    local x, y, w, h = x or 0, y or 0, w or _LIKO_W, h or _LIKO_H
    x = Verify(x,"X","number",true)
    y = Verify(y,"Y","number",true)
    w = Verify(w,"W","number",true)
    h = Verify(h,"H","number",true)
    love.graphics.setCanvas()
    local imgdata = GPU.imagedata(_ScreenCanvas:newImageData(1,1,x,y,w,h))
    love.graphics.setCanvas{_ScreenCanvas,stencil=true}
    return imgdata
  end
  
  function GPU.getLabelImage()
    return GPU.imagedata(LabelImage)
  end
  
  --Mouse API--
  
  --Returns the current position of the mouse.
  function GPU.getMPos()
    return _HostToLiko(love.mouse.getPosition()) --Convert the mouse position
  end
  
  --Returns if the given mouse button is down
  function GPU.isMDown(b)
    b = Verify(b,"Button","number")
    return love.mouse.isDown(b)
  end
  
  --Gif Recording Controlling API--
  GPU.startGifRecording = startGifRecording
  GPU.pauseGifRecording = pauseGifRecording
  GPU.endGifRecording = endGifRecording
  
  function GPU.isGifRecording()
    return _GIFRec and true or false
  end
  
  --Cursor API--
  function GPU.cursor(imgdata,name,hx,hy)
    if type(imgdata) == "string" then --Set the current cursor
      if _GrappedCursor then if not name then _AlwaysDraw = false; _ShouldDraw = true end elseif name then _AlwaysDraw = true end
      if _Cursor == imgdata and not ((_GrappedCursor and not name) or (name and not _GrappedCursor)) then return end
      _GrappedCursor = name
      if (not _CursorsCache[imgdata]) and (imgdata ~= "none") then return error("Cursor doesn't exists: "..imgdata) end
      _Cursor = imgdata
      if _Cursor == "none" or _GrappedCursor then
        love.mouse.setVisible(false)
      elseif love.mouse.isCursorSupported() then
        love.mouse.setVisible(true)
        love.mouse.setCursor(_CursorsCache[_Cursor].cursor)
      end
    elseif type(imgdata) == "table" then --Create a new cursor from an image.
      if not( imgdata.enlarge and imgdata.export and imgdata.type ) then return error("Invalied image") end
      if imgdata:type() ~= "GPU.imageData" then return error("Invalied image object") end
      
      local name = name or "default"
      Verify(name,"Name","string")
      
      local hx, hy = hx or 0, hy or 0
      hx = Verify(hx,"Hot X","number",true)
      hy = Verify(hy,"Hot Y","number",true)
      
      local enimg = imgdata:enlarge(_LIKOScale)
      local img = love.graphics.newImage(love.filesystem.newFileData(imgdata:export(),"cursor.png"))
      local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
      local gifimg = love.image.newImageData(imgdata:size())
      gifimg:mapPixel(function(x,y) return imgdata:getPixel(x,y)/255,0,0,1 end)
      gifimg:mapPixel(_EncodeTransparent)
      gifimg = love.graphics.newImage(gifimg)
      
      local hotx, hoty = hx*math.floor(_LIKOScale), hy*math.floor(_LIKOScale) --Converted to host scale
      local cur = love.mouse.isCursorSupported() and love.mouse.newCursor(limg,hotx,hoty) or {}
      local palt = {}
      for i=1, 16 do
        table.insert(palt,_ImageTransparent[i])
      end
      _CursorsCache[name] = {cursor=cur,imgdata=imgdata,gifimg=gifimg,hx=hx,hy=hy,palt=palt}
    elseif type(imgdata) == "nil" then
      if _Cursor == "none" then
        return _Cursor
      else
        return _Cursor, _CursorsCache[_Cursor].imgdata, _CursorsCache[_Cursor].hx+1, _CursorsCache[_Cursor].hy+1
      end
    else --Invalied
      return error("The first argument must be a string, image or nil")
    end
  end
  
  events:register("love:resize",function() --The new size will be calculated in the top, because events are called by the order they were registered with
    if not love.mouse.isCursorSupported() then return end
    for k, cursor in pairs(_CursorsCache) do
       --Hack
      GPU.pushPalette()
      GPU.pushPalette()
      for i=1, 16 do
        PaletteStack[#PaletteStack].trans[i] = cursor.palt[i]
      end
      GPU.popPalette()
      
      local enimg = cursor.imgdata:enlarge(_LIKOScale)
      local limg = love.image.newImageData(love.filesystem.newFileData(enimg:export(),"cursor.png")) --Take it out to love image object
      local hotx, hoty = cursor.hx*math.floor(_LIKOScale), cursor.hy*math.floor(_LIKOScale) --Converted to host scale
      local cur = love.mouse.newCursor(limg,hotx,hoty)
      _CursorsCache[k].cursor = cur
      GPU.popPalette()
    end
    local cursor = _Cursor; _Cursor = "none" --Force the cursor to update.
    GPU.cursor(cursor,_GrappedCursor)
  end)
  
  GPU.cursor(GPU.imagedata(1,1):setPixel(0,0,7),"default")
  GPU.cursor(_Cursor)
  
  --Screenshot and LabelCapture keys handling.
  events:register("love:keypressed", function(key,sc,isrepeat)
    if key == _ScreenshotKey then
      local sc = GPU.screenshot()
      sc = sc:enlarge(_ScreenshotScale)
      local png = sc:exportOpaque()
      love.filesystem.write("/LIKO12-"..os.time()..".png",png)
      systemMessage("Screenshot has been taken successfully",2)
    elseif key == _LabelCaptureKey then
      love.graphics.setCanvas()
      LabelImage:paste(_ScreenCanvas:newImageData(),0,0,0,0,_LIKO_W,_LIKO_H)
      love.graphics.setCanvas{_ScreenCanvas,stencil=true}
      systemMessage("Captured label image successfully !",2)
    end
  end)
  
  function GPU._systemMessage(msg,time,tcol,col,hideInGif)
    return systemMessage(msg,time,tcol,col,hideInGif)
  end
  
  events:register("love:update",function(dt)
    if MSGTimer > 0 then
      MSGTimer = MSGTimer - dt
      _ShouldDraw = true
    end
  end)
  
  --End of API--
  
  love.graphics.setLineStyle("rough") --Set the line style.
  love.graphics.setLineJoin("miter") --Set the line join style.
  love.graphics.setPointSize(1) --Set the point size to 1px.
  love.graphics.setLineWidth(1) --Set the line width to 1px.
  setColor(_GetColor(0)) --Set the active color to black.
  love.mouse.setVisible(false)
  
  GPU.clear() --Clear the canvas for the first time.
  
  --Host to love.run when graphics is active--
  events:register("love:graphics",function()
    
    _Flipped = true --Set the flipped flag
    
    if _ShouldDraw or _AlwaysDraw or _AlwaysDrawTimer > 0 or _DevKitDraw or _ActiveShader then --When it's required to draw (when changes has been made to the canvas)
      UnbindVRAM(true) --Make sure that the VRAM changes are applied
      
      if PatternFill then
        love.graphics.setStencilTest()
      end
      
      love.graphics.setCanvas() --Quit the canvas and return to the host screen.
      love.graphics.push()
      love.graphics.setShader(_DisplayShader) --Activate the display shader.
      love.graphics.origin() --Reset all transformations.
      if Clip then love.graphics.setScissor() end
      
      GPU.pushColor() --Push the current color to the stack.
      love.graphics.setColor(1,1,1,1) --I don't want to tint the canvas :P
      if _ClearOnRender then love.graphics.clear((_HOST_H > _HOST_W) and {25/255,25/255,25/255,1} or {0,0,0,1}) end --Clear the screen (Some platforms are glitching without this).
      
      if _ActiveShader then
        if not _Mobile then love.mouse.setVisible(false) end
        love.graphics.setCanvas(_BackBuffer)
        love.graphics.clear(0,0,0,0)
        love.graphics.draw(_ScreenCanvas) --Draw the canvas.
        if _Cursor ~= "none" then
          local mx, my = _HostToLiko(love.mouse.getPosition())
          local hotx, hoty = _CursorsCache[_Cursor].hx, _CursorsCache[_Cursor].hy
          love.graphics.draw(_CursorsCache[_Cursor].gifimg, ofs.image[1]+mx-hotx, ofs.image[2]+my-hoty)
        end
        if _PostShaderTimer then _ActiveShader:send("time",math.floor(_PostShaderTimer*1000)) end
        love.graphics.setShader(_ActiveShader)
        love.graphics.setCanvas()
        love.graphics.draw(_BackBuffer, _LIKO_X+ofs.screen[1], _LIKO_Y+ofs.screen[2], 0, _LIKOScale, _LIKOScale) --Draw the canvas.
        love.graphics.setShader(_DisplayShader)
      else
        love.graphics.draw(_ScreenCanvas, _LIKO_X+ofs.screen[1], _LIKO_Y+ofs.screen[2], 0, _LIKOScale, _LIKOScale) --Draw the canvas.
      end
      
      if _GrappedCursor and _Cursor ~= "none" and not _ActiveShader then --Must draw the cursor using the gpu
        local mx, my = _HostToLiko(love.mouse.getPosition())
        mx,my = _LikoToHost(mx,my)
        local hotx, hoty = _CursorsCache[_Cursor].hx*_LIKOScale, _CursorsCache[_Cursor].hy*_LIKOScale --Converted to host scale
        love.graphics.draw(_CursorsCache[_Cursor].gifimg, ofs.image[1]+mx-hotx, ofs.image[2]+my-hoty,0,_LIKOScale,_LIKOScale)
      end
      
      love.graphics.setShader() --Deactivate the display shader.
      
      if MSGTimer > 0 then
        setColor(_GetColor(LastMSGColor))
        love.graphics.rectangle("fill", _LIKO_X+ofs.screen[1]+ofs.rect[1], _LIKO_Y+ofs.screen[2] + (_LIKO_H-8) * _LIKOScale + ofs.rect[2],
        _LIKO_W * _LIKOScale + ofs.rectSize[1], 8*_LIKOScale + ofs.rectSize[2])
        setColor(_GetColor(LastMSGTColor))
        love.graphics.push()
        love.graphics.translate(_LIKO_X+ofs.screen[1]+ofs.print[1]+_LIKOScale, _LIKO_Y+ofs.screen[2] + (_LIKO_H-7) * _LIKOScale + ofs.print[2])
        love.graphics.scale(_LIKOScale,_LIKOScale)
        love.graphics.print(LastMSG,0,0)
        love.graphics.pop()
        love.graphics.setColor(1,1,1,1)
      end
      
      if _DevKitDraw then
        events:trigger("GPU:DevKitDraw")
        love.graphics.origin()
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineStyle("rough")
        love.graphics.setLineJoin("miter")
        love.graphics.setPointSize(1)
        love.graphics.setLineWidth(1)
        love.graphics.setShader()
        love.graphics.setCanvas()
      end
      
      love.graphics.present() --Present the screen to the host & the user.
      love.graphics.setShader(_DrawShader) --Reactivate the draw shader.
      love.graphics.pop()
      love.graphics.setCanvas{_ScreenCanvas,stencil=true} --Reactivate the canvas.
      
      if PatternFill then
        love.graphics.stencil(PatternFill, "replace", 1)
        love.graphics.setStencilTest("greater",0)
      end
      
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
    
    if _AlwaysDrawTimer > 0 then
      _AlwaysDrawTimer = _AlwaysDrawTimer - dt
    end
    
    if not _GIFRec then return end
    _GIFTimer = _GIFTimer + dt
    if _GIFTimer >= _GIFFrameTime then
      _GIFTimer = _GIFTimer % _GIFFrameTime
      love.graphics.setCanvas() --Quit the canvas and return to the host screen.
      
      if PatternFill then
        love.graphics.setStencilTest()
      end
      
      love.graphics.push()
      love.graphics.origin() --Reset all transformations.
      if Clip then love.graphics.setScissor() end
      
      GPU.pushColor() --Push the current color to the stack.
      love.graphics.setColor(1,1,1,1) --I don't want to tint the canvas :P
      
      love.graphics.setCanvas(_GIFCanvas)
      
      love.graphics.clear(0,0,0,1) --Clear the screen (Some platforms are glitching without this).
      
      love.graphics.setColor(1,1,1,1)
      
      love.graphics.setShader()
      
      love.graphics.draw(_ScreenCanvas, ofs.screen[1], ofs.screen[2], 0, _GIFScale, _GIFScale) --Draw the canvas.
      
      if _Cursor ~= "none" then --Draw the cursor
        local cx, cy = GPU.getMPos()
        love.graphics.draw(_CursorsCache[_Cursor].gifimg,(cx-_CursorsCache[_Cursor].hx)*_GIFScale-1,(cy-_CursorsCache[_Cursor].hy)*_GIFScale-1,0,_GIFScale,_GIFScale)
      end
      
      if MSGTimer > 0 and LastMSGGif then
        setColor(LastMSGColor/255,0,0,1)
        love.graphics.rectangle("fill", ofs.screen[1]+ofs.rect[1], ofs.screen[2] + (_LIKO_H-8) * _GIFScale + ofs.rect[2],
        _LIKO_W *_GIFScale + ofs.rectSize[1], 8*_GIFScale + ofs.rectSize[2])
        setColor(LastMSGTColor/255,0,0,1)
        love.graphics.push()
        love.graphics.translate(ofs.screen[1]+ofs.print[1]+_GIFScale, ofs.screen[2] + (_LIKO_H-7) * _GIFScale + ofs.print[2])
        love.graphics.scale(_GIFScale,_GIFScale)
        love.graphics.print(LastMSG,0,0)
        love.graphics.pop()
        love.graphics.setColor(1,1,1,1)
      end
      
      love.graphics.setCanvas()
      love.graphics.setShader(_DrawShader)
      
      love.graphics.pop() --Reapply the offset.
      love.graphics.setCanvas{_ScreenCanvas,stencil=true} --Reactivate the canvas.
      
      if PatternFill then
        love.graphics.stencil(PatternFill, "replace", 1)
        love.graphics.setStencilTest("greater",0)
      end
      
      if Clip then love.graphics.setScissor(unpack(Clip)) end
      GPU.popColor() --Restore the active color.
      
      if _GIFPChanged then
        _GIFPal = ""
        for i=0,15 do
          local p = _ColorSet[i]
          _GIFPal = _GIFPal .. string.char(p[1],p[2],p[3])
        end
        if _GIFPal == _GIFPStart then
          _GIFPal = false
        end
      end
      
      _GIFRec:frame(_GIFCanvas:newImageData(),_GIFPal,_GIFPChanged)
      
      _GIFPChanged = false
    end
  end)
  
  local devkit = {}
  devkit._LIKO_W = _LIKO_W
  devkit._LIKO_H = _LIKO_H
  devkit._LIKO_X = _LIKO_X
  devkit._LIKO_Y = _LIKO_Y
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
  devkit.BindVRAM = BindVRAM
  devkit.UnbindVRAM = UnbindVRAM
  devkit._ExportImage = _ExportImage
  devkit._ExportImageOpaque = _ExportImageOpaque
  devkit.VRAMHandler = VRAMHandler
  devkit.LIMGHandler = LIMGHandler
  devkit.LabelImage = LabelImage
  devkit.indirect = indirect
  
  function devkit.DevKitDraw(bool)
    _DevKitDraw = bool
  end
  
  return GPU, yGPU, devkit --Return the table containing all of the api functions.
end
