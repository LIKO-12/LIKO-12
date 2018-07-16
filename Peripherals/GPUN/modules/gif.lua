--GPU: Gif recording.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local events = require("Engine.events")

local Path = GPUKit.Path
local GifKit = GPUKit.Gif
local WindowKit = GPUKit.Window
local PaletteKit = GPUKit.Palette
local RenderKit = GPUKit.RenderKit
local CalibrationKit = GPUKit.Calibration
local MiscKit = GPUKit.MiscKit

--==Kits Constants==--

local systemMessage = MiscKit.systemMessage
local _ColorSet = PaletteKit.ColorSet
local ofs = CalibrationKit.Offsets
local _LIKO_W = WindowKit.LIKO_W
local _LIKO_H = WindowKit.LIKO_H

--==Local Variables==--
local _GIFScale = math.floor(Config._GIFScale or 2) --The gif scale factor (must be int).
local _GIFStartKey = Config._GIFStartKey or "f8"
local _GIFEndKey = Config._GIFEndKey or "f9"
local _GIFPauseKey = Config._GIFPauseKey or "f7"
local _GIFFrameTime = (Config._GIFFrameTime or 1/60)*2  --The delta timr between each gif frame.
local _GIFTimer, _GIFRec = 0
local _GIFPStart --The gif starting palette compairing string.
local _GIFPal --The gif palette string, should be 16*3 bytes long.

GifKit.PChanged = false --A flag to indicate that the palette did change while gif recording

--==Canvas Creation==--

local _CanvasFormats = love.graphics.getCanvasFormats()

local _GIFCanvas = love.graphics.newCanvas(_LIKO_W*_GIFScale,_LIKO_H*_GIFScale,{
  format = (_CanvasFormats.r8 and "r8" or "normal"),
  dpiscale = 1
}) --Create the gif canvas, used to apply the gif scale factor.

--GifRecorder
local _GIF = love.filesystem.load(Path.."scripts/gif.lua")( _GIFScale, _LIKO_W, _LIKO_H ) --Load the gif library

local function startGifRecording()
  if _GIFRec then return end --If there is an already in progress gif
  if love.filesystem.getInfo("/~gifrec.gif","file") then
    _GIFRec = _GIF.continue("/~gifrec.gif")
    _GIFPStart = love.filesystem.read("/~gifrec.pal")
    GifKit.PChanged = true --To check if it's the same palette
    _GIFPal = false
    systemMessage("Resumed gif recording",1,false,false,true)
    return
  end
  _GIFRec = _GIF.new("/~gifrec.gif",_ColorSet)
  GifKit.PChanged = false
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
  love.filesystem.write("/GIF Recordings/LIKO12-"..os.time()..".gif",love.filesystem.read("/~gifrec.gif"))
  love.filesystem.remove("/~gifrec.gif")
  love.filesystem.remove("/~gifrec.pal")
end

--To handle gif control buttons
events.register("love:keypressed", function(key)
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
events.register("love:reboot",function()
  if _GIFRec then
    _GIFRec.file:flush()
    _GIFRec.file:close()
    _GIFRec = nil
    
    love.filesystem.write("/~gifreboot.gif",love.filesystem.read("/~gifrec.gif"))
    love.filesystem.remove("/~gifrec.gif")
  end
end)
--To save the gif before quitting.
events.register("love:quit", function()
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

--==GPU GIF API==--

GPU.startGifRecording = startGifRecording
GPU.pauseGifRecording = pauseGifRecording
GPU.endGifRecording = endGifRecording

function GPU.isGifRecording()
  return _GIFRec and true or false
end
  
--==Recorder==--

events.register("love:update",function(dt)
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
    
    love.graphics.draw(RenderKit.ScreenCanvas, ofs.screen[1], ofs.screen[2], 0, _GIFScale, _GIFScale) --Draw the canvas.
    
    if _Cursor ~= "none" then --Draw the cursor
      local cx, cy = GPU.getMPos()
      love.graphics.draw(_CursorsCache[_Cursor].gifimg,(cx-_CursorsCache[_Cursor].hx)*_GIFScale-1,(cy-_CursorsCache[_Cursor].hy)*_GIFScale-1,0,_GIFScale,_GIFScale)
    end
    
    if MiscKit.MSGTimer > 0 and MiscKit.LastMSGGif then
      love.graphics.setColor(MiscKit.LastMSGColor/255,0,0,1)
      love.graphics.rectangle("fill", ofs.screen[1]+ofs.rect[1], ofs.screen[2] + (_LIKO_H-8) * _GIFScale + ofs.rect[2],
      _LIKO_W *_GIFScale + ofs.rectSize[1], 8*_GIFScale + ofs.rectSize[2])
      love.graphics.setColor(MiscKit.LastMSGTColor/255,0,0,1)
      love.graphics.push()
      love.graphics.translate(ofs.screen[1]+ofs.print[1]+_GIFScale, ofs.screen[2] + (_LIKO_H-7) * _GIFScale + ofs.print[2])
      love.graphics.scale(_GIFScale,_GIFScale)
      love.graphics.print(MiscKit.LastMSG,0,0)
      love.graphics.pop()
      love.graphics.setColor(1,1,1,1)
    end
    
    love.graphics.setCanvas()
    love.graphics.setShader(RenderKit.DrawShader)
    
    love.graphics.pop() --Reapply the offset.
    love.graphics.setCanvas{RenderKit.ScreenCanvas,stencil=true} --Reactivate the canvas.
    
    if PatternFill then
      love.graphics.stencil(PatternFill, "replace", 1)
      love.graphics.setStencilTest("greater",0)
    end
    
    if Clip then love.graphics.setScissor(unpack(Clip)) end
    GPU.popColor() --Restore the active color.
    
    if GifKit.PChanged then
      _GIFPal = ""
      for i=0,15 do
        local p = _ColorSet[i]
        _GIFPal = _GIFPal .. string.char(p[1],p[2],p[3])
      end
      if _GIFPal == _GIFPStart then
        _GIFPal = false
      end
    end
    
    _GIFRec:frame(_GIFCanvas:newImageData(),_GIFPal,GifKit.PChanged)
    
    GifKit.PChanged = false
  end
end)