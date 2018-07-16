--GPU: Canvas into window rendering.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local events = require("Engine.events")
local coreg = require("Engine.coreg")

local Path = GPUKit.Path
local MiscKit = GPUKit.MiscKit
local VRamKit = GPUKit.VRamKit
local CursorKit = GPUKit.Cursor
local SharedKit = GPUKit.Shared
local RenderKit = GPUKit.Render
local WindowKit = GPUKit.Window
local MatrixKit = GPUKit.Matrix
local PaletteKit = GPUKit.Palette
local PShadersKit = GPUKit.PShaders
local CalibrationKit = GPUKit.Calibration

--==Kits Constants==--
local _DrawPalette = PaletteKit.DrawPalette
local _ImagePalette = PaletteKit.ImagePalette
local _ImageTransparent = PaletteKit.ImageTransparent
local _DisplayPalette = PaletteKit.DisplayPalette
local _LIKO_W = WindowKit.LIKO_W
local _LIKO_H = WindowKit.LIKO_H
local UnbindVRAM = VRamKit.UnbindVRAM
local setColor = SharedKit.setColor
local _GetColor = PaletteKit.GetColor
local _LikoToHost = WindowKit.LikoToHost
local _HostToLiko = WindowKit.HostToLiko
local _CursorsCache = CursorKit.CursorsCache

--==Kit Variables==--
RenderKit.ShouldDraw = false --This flag means that the gpu has to update the screen for the user.
RenderKit.AlwaysDraw = false --This flag means that the gpu has to always update the screen for the user.
RenderKit.DevKitDraw = false --This flag means that the gpu has to always update the screen for the user, set by other peripherals
RenderKit.AlwaysDrawTimer = 0 --This timer is only used on mobile devices to keep drawing the screen when the user changes the orientation.

--==Local Variables==--

local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS" or Config._Mobile

local _ClearOnRender = Config._ClearOnRender --Should clear the screen when render, some platforms have glitches when this is disabled.
if type(_ClearOnRender) == "nil" then _ClearOnRender = true end --Defaults to be enabled.

local ofs = CalibrationKit.Offsets

local flip = false --Is the code waiting for the screen to draw, used to resume the coroutine.
local _Flipped = false --This flag means that the screen has been flipped

--==Canvases Creations==--

local _CanvasFormats = love.graphics.getCanvasFormats()

local _ScreenCanvas = love.graphics.newCanvas(_LIKO_W, _LIKO_H,{
    format = (_CanvasFormats.r8 and "r8" or "normal"),
    dpiscale = 1
  }) --Create the screen canvas.

local _BackBuffer = love.graphics.newCanvas(_LIKO_W, _LIKO_H,{dpiscale=1}) --BackBuffer for post shaders.

--==Render Shaders==--

local _Shaders = love.filesystem.load(Path.."scripts/shaders.lua")()

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

--==GPU Render API==--
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
  UnbindVRAM() RenderKit.ShouldDraw = true -- Incase if no changes are made so doesn't suspend forever
  flip = true
  return 2 --Do not resume automatically
end

--==Graphics Initialization==--

love.graphics.setCanvas{_ScreenCanvas,stencil=true} --Activate LIKO12 canvas.
love.graphics.clear(0,0,0,1) --Clear LIKO12 screen for the first time.

love.graphics.setShader(_DrawShader) --Activate the drawing shader.

GPU.cursor(GPU.imagedata(1,1):setPixel(0,0,7),"default")
GPU.cursor(CursorKit.Cursor)

setColor(_GetColor(0)) --Set the active color to black.
love.mouse.setVisible(false)

GPU.clear() --Clear the canvas for the first time.

--==Events==--

--Always draw timer
events.register("love:update",function(dt)
  if RenderKit.AlwaysDrawTimer > 0 then
    RenderKit.AlwaysDrawTimer = RenderKit.AlwaysDrawTimer - dt
  end
end)

--==Renderer==--
--Host to love.run when graphics is active--
events.register("love:graphics",function()
  _Flipped = true --Set the flipped flag

  if RenderKit.ShouldDraw or RenderKit.AlwaysDraw or RenderKit.AlwaysDrawTimer > 0 or RenderKit.DevKitDraw or PShadersKit.ActiveShader then --When it's required to draw (when changes has been made to the canvas)
    UnbindVRAM(true) --Make sure that the VRAM changes are applied

    if MatrixKit.PatternFill then
      love.graphics.setStencilTest()
    end

    love.graphics.setCanvas() --Quit the canvas and return to the host screen.
    love.graphics.push()
    love.graphics.setShader(_DisplayShader) --Activate the display shader.
    love.graphics.origin() --Reset all transformations.
    if MatrixKit.Clip then love.graphics.setScissor() end

    GPU.pushColor() --Push the current color to the stack.
    love.graphics.setColor(1,1,1,1) --I don't want to tint the canvas :P
    if _ClearOnRender then love.graphics.clear((WindowKit.HOST_H > WindowKit.HOST_W) and {25/255,25/255,25/255,1} or {0,0,0,1}) end --Clear the screen (Some platforms are glitching without this).

    if PShadersKit.ActiveShader then
      if not _Mobile then love.mouse.setVisible(false) end
      love.graphics.setCanvas(_BackBuffer)
      love.graphics.clear(0,0,0,0)
      love.graphics.draw(_ScreenCanvas) --Draw the canvas.
      if CursorKit.Cursor ~= "none" then
        local mx, my = _HostToLiko(love.mouse.getPosition())
        local hotx, hoty = _CursorsCache[CursorKit.Cursor].hx, _CursorsCache[CursorKit.Cursor].hy
        love.graphics.draw(_CursorsCache[CursorKit.Cursor].gifimg, ofs.image[1]+mx-hotx, ofs.image[2]+my-hoty)
      end
      if PShadersKit.PostShaderTimer then PShadersKit.ActiveShader:send("time",math.floor(PShadersKit.PostShaderTimer*1000)) end
      love.graphics.setShader(PShadersKit.ActiveShader)
      love.graphics.setCanvas()
      love.graphics.draw(_BackBuffer, WindowKit.LIKO_X+ofs.screen[1], WindowKit.LIKO_Y+ofs.screen[2], 0, WindowKit.LIKOScale, WindowKit.LIKOScale) --Draw the canvas.
      love.graphics.setShader(_DisplayShader)
    else
      love.graphics.draw(_ScreenCanvas, WindowKit.LIKO_X+ofs.screen[1], WindowKit.LIKO_Y+ofs.screen[2], 0, WindowKit.LIKOScale, WindowKit.LIKOScale) --Draw the canvas.
    end

    if CursorKit.GrappedCursor and CursorKit.Cursor ~= "none" and not PShadersKit.ActiveShader then --Must draw the cursor using the gpu
      local mx, my = _HostToLiko(love.mouse.getPosition())
      mx,my = _LikoToHost(mx,my)
      local hotx, hoty = _CursorsCache[CursorKit.Cursor].hx*WindowKit.LIKOScale, _CursorsCache[CursorKit.Cursor].hy*WindowKit.LIKOScale --Converted to host scale
      love.graphics.draw(_CursorsCache[CursorKit.Cursor].gifimg, ofs.image[1]+mx-hotx, ofs.image[2]+my-hoty,0,WindowKit.LIKOScale,WindowKit.LIKOScale)
    end

    love.graphics.setShader() --Deactivate the display shader.

    if MiscKit.MSGTimer > 0 then
      setColor(_GetColor(MiscKit.LastMSGColor))
      love.graphics.rectangle("fill", WindowKit.LIKO_X+ofs.screen[1]+ofs.rect[1], WindowKit.LIKO_Y+ofs.screen[2] + (_LIKO_H-8) * WindowKit.LIKOScale + ofs.rect[2],
        _LIKO_W * WindowKit.LIKOScale + ofs.rectSize[1], 8*WindowKit.LIKOScale + ofs.rectSize[2])
      setColor(_GetColor(MiscKit.LastMSGTColor))
      love.graphics.push()
      love.graphics.translate(WindowKit.LIKO_X+ofs.screen[1]+ofs.print[1]+WindowKit.LIKOScale, WindowKit.LIKO_Y+ofs.screen[2] + (_LIKO_H-7) * WindowKit.LIKOScale + ofs.print[2])
      love.graphics.scale(WindowKit.LIKOScale,WindowKit.LIKOScale)
      love.graphics.print(MiscKit.LastMSG,0,0)
      love.graphics.pop()
      love.graphics.setColor(1,1,1,1)
    end

    if RenderKit.DevKitDraw then
      events.trigger("GPU:DevKitDraw")
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

    if MatrixKit.PatternFill then
      love.graphics.stencil(MatrixKit.PatternFill, "replace", 1)
      love.graphics.setStencilTest("greater",0)
    end

    if MatrixKit.Clip then love.graphics.setScissor(unpack(MatrixKit.Clip)) end
    RenderKit._ShouldDraw = false --Reset the flag.
    GPU.popColor() --Restore the active color.
    if flip then
      flip = false
      coreg.resumeCoroutine(true)
    end
  end

end)

--==GPUKit Exports==--
RenderKit.DrawShader = _DrawShader
RenderKit.ImageShader = _ImageShader
RenderKit.DisplayShader = _DisplayShader
RenderKit.StencilShader = _StencilShader
RenderKit.ScreenCanvas = _ScreenCanvas

--==DevKit Exports==--
DevKit._DrawShader = _DrawShader
DevKit._ImageShader = _ImageShader
DevKit._DisplayShader = _DisplayShader