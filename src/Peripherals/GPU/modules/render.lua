--GPU: Canvas into window rendering.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local lg = love.graphics

local events = require("Engine.events")
local coreg = require("Engine.coreg")

local Path = GPUVars.Path
local MiscVars = GPUVars.Misc
local VRamVars = GPUVars.VRam
local CursorVars = GPUVars.Cursor
local SharedVars = GPUVars.Shared
local RenderVars = GPUVars.Render
local WindowVars = GPUVars.Window
local MatrixVars = GPUVars.Matrix
local PaletteVars = GPUVars.Palette
local PShadersVars = GPUVars.PShaders
local CalibrationVars = GPUVars.Calibration

--==Varss Constants==--
local _DrawPalette = PaletteVars.DrawPalette
local _ImagePalette = PaletteVars.ImagePalette
local _ImageTransparent = PaletteVars.ImageTransparent
local _DisplayPalette = PaletteVars.DisplayPalette
local _LIKO_W = WindowVars.LIKO_W
local _LIKO_H = WindowVars.LIKO_H
local UnbindVRAM = VRamVars.UnbindVRAM
local setColor = SharedVars.setColor
local _GetColor = PaletteVars.GetColor
local _LikoToHost = WindowVars.LikoToHost
local _HostToLiko = WindowVars.HostToLiko
local _CursorsCache = CursorVars.CursorsCache

--==Vars Variables==--

RenderVars.ShouldDraw = false --This flag means that the gpu has to update the screen for the user.
RenderVars.AlwaysDraw = false --This flag means that the gpu has to always update the screen for the user.
RenderVars.DevKitDraw = false --This flag means that the gpu has to always update the screen for the user, set by other peripherals
RenderVars.AlwaysDrawTimer = 0 --This timer is only used on mobile devices to keep drawing the screen when the user changes the orientation.

--==Local Variables==--

local _Mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS" or Config._Mobile

local _ClearOnRender = Config._ClearOnRender --Should clear the screen when render, some platforms have glitches when this is disabled.
if type(_ClearOnRender) == "nil" then _ClearOnRender = true end --Defaults to be enabled.

local ofs = CalibrationVars.Offsets

local flip = false --Is the code waiting for the screen to draw, used to resume the coroutine.
local _Flipped = false --This flag means that the screen has been flipped

--==Canvases Creations==--

local _CanvasFormats = lg.getCanvasFormats()

local _ScreenCanvas = lg.newCanvas(_LIKO_W, _LIKO_H,{
    format = (_CanvasFormats.r8 and "r8" or "normal"),
    dpiscale = 1
  }) --Create the screen canvas.

local _BackBuffer = lg.newCanvas(_LIKO_W, _LIKO_H,{dpiscale=1}) --BackBuffer for post shaders.

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
  UnbindVRAM() RenderVars.ShouldDraw = true -- Incase if no changes are made so doesn't suspend forever
  flip = true
  return 2 --Do not resume automatically
end

--==Graphics Initialization==--

lg.setCanvas{_ScreenCanvas,stencil=true} --Activate LIKO12 canvas.
lg.clear(0,0,0,1) --Clear LIKO12 screen for the first time.

lg.setShader(_DrawShader) --Activate the drawing shader.

GPU.cursor(GPU.imagedata(1,1):setPixel(0,0,7),"default")
GPU.cursor(CursorVars.Cursor)

setColor(_GetColor(0)) --Set the active color to black.
love.mouse.setVisible(false)

GPU.clear() --Clear the canvas for the first time.

--==Events==--

--Always draw timer
events.register("love:update",function(dt)
  if RenderVars.AlwaysDrawTimer > 0 then
    RenderVars.AlwaysDrawTimer = RenderVars.AlwaysDrawTimer - dt
  end
end)

--==Renderer==--
--Host to love.run when graphics is active--
events.register("love:graphics",function()
  _Flipped = true --Set the flipped flag

  if RenderVars.ShouldDraw or RenderVars.AlwaysDraw or RenderVars.AlwaysDrawTimer > 0 or RenderVars.DevKitDraw or PShadersVars.ActiveShader then --When it's required to draw (when changes has been made to the canvas)
    UnbindVRAM(true) --Make sure that the VRAM changes are applied

    if MatrixVars.PatternFill then
      lg.setStencilTest()
    end

    lg.setCanvas() --Quit the canvas and return to the host screen.
    lg.push()
    lg.setShader(_DisplayShader) --Activate the display shader.
    lg.origin() --Reset all transformations.
    if MatrixVars.Clip then lg.setScissor() end

    GPU.pushColor() --Push the current color to the stack.
    lg.setColor(1,1,1,1) --I don't want to tint the canvas :P
    if _ClearOnRender then lg.clear((WindowVars.Height > WindowVars.Width) and {25/255,25/255,25/255,1} or {0,0,0,1}) end --Clear the screen (Some platforms are glitching without this).

    if PShadersVars.ActiveShader then
      if not _Mobile then love.mouse.setVisible(false) end
      lg.setCanvas(_BackBuffer)
      lg.clear(0,0,0,0)
      lg.draw(_ScreenCanvas) --Draw the canvas.
      if CursorVars.Cursor ~= "none" then
        local mx, my = _HostToLiko(love.mouse.getPosition())
        local hotx, hoty = _CursorsCache[CursorVars.Cursor].hx, _CursorsCache[CursorVars.Cursor].hy
        lg.draw(_CursorsCache[CursorVars.Cursor].gifimg, ofs.image[1]+mx-hotx, ofs.image[2]+my-hoty)
      end
      if PShadersVars.PostShaderTimer then PShadersVars.ActiveShader:send("time",math.floor(PShadersVars.PostShaderTimer*1000)) end
      lg.setShader(PShadersVars.ActiveShader)
      lg.setCanvas()
      lg.draw(_BackBuffer, WindowVars.LIKO_X+ofs.screen[1], WindowVars.LIKO_Y+ofs.screen[2], 0, WindowVars.LIKOScale, WindowVars.LIKOScale) --Draw the canvas.
      lg.setShader(_DisplayShader)
    else
      lg.draw(_ScreenCanvas, WindowVars.LIKO_X+ofs.screen[1], WindowVars.LIKO_Y+ofs.screen[2], 0, WindowVars.LIKOScale, WindowVars.LIKOScale) --Draw the canvas.
    end

    if CursorVars.GrappedCursor and CursorVars.Cursor ~= "none" and not PShadersVars.ActiveShader then --Must draw the cursor using the gpu
      local mx, my = _HostToLiko(love.mouse.getPosition())
      mx,my = _LikoToHost(mx,my)
      local hotx, hoty = _CursorsCache[CursorVars.Cursor].hx*WindowVars.LIKOScale, _CursorsCache[CursorVars.Cursor].hy*WindowVars.LIKOScale --Converted to host scale
      lg.draw(_CursorsCache[CursorVars.Cursor].gifimg, ofs.image[1]+mx-hotx, ofs.image[2]+my-hoty,0,WindowVars.LIKOScale,WindowVars.LIKOScale)
    end

    lg.setShader() --Deactivate the display shader.

    if MiscVars.MSGTimer > 0 then
      setColor(_GetColor(MiscVars.LastMSGColor))
      lg.rectangle("fill", WindowVars.LIKO_X+ofs.screen[1]+ofs.rect[1], WindowVars.LIKO_Y+ofs.screen[2] + (_LIKO_H-8) * WindowVars.LIKOScale + ofs.rect[2],
        _LIKO_W * WindowVars.LIKOScale + ofs.rectSize[1], 8*WindowVars.LIKOScale + ofs.rectSize[2])
      setColor(_GetColor(MiscVars.LastMSGTColor))
      lg.push()
      lg.translate(WindowVars.LIKO_X+ofs.screen[1]+ofs.print[1]+WindowVars.LIKOScale, WindowVars.LIKO_Y+ofs.screen[2] + (_LIKO_H-7) * WindowVars.LIKOScale + ofs.print[2])
      lg.scale(WindowVars.LIKOScale,WindowVars.LIKOScale)
      lg.print(MiscVars.LastMSG,0,0)
      lg.pop()
      lg.setColor(1,1,1,1)
    end

    if RenderVars.DevKitDraw then
      events.trigger("GPU:DevKitDraw")
      lg.origin()
      lg.setColor(1,1,1,1)
      lg.setLineStyle("rough")
      lg.setLineJoin("miter")
      lg.setPointSize(1)
      lg.setLineWidth(1)
      lg.setShader()
      lg.setCanvas()
    end

    lg.present() --Present the screen to the host & the user.
    lg.setShader(_DrawShader) --Reactivate the draw shader.
    lg.pop()
    lg.setCanvas{_ScreenCanvas,stencil=true} --Reactivate the canvas.

    if MatrixVars.PatternFill then
      lg.stencil(MatrixVars.PatternFill, "replace", 1)
      lg.setStencilTest("greater",0)
    end

    if MatrixVars.Clip then lg.setScissor(MatrixVars.Clip[1], MatrixVars.Clip[2], MatrixVars.Clip[3], MatrixVars.Clip[4]) end
    RenderVars._ShouldDraw = false --Reset the flag.
    GPU.popColor() --Restore the active color.
    if flip then
      flip = false
      coreg.resumeCoroutine(true)
    end
  end

end)

--==GPUVars Exports==--
RenderVars.DrawShader = _DrawShader
RenderVars.ImageShader = _ImageShader
RenderVars.DisplayShader = _DisplayShader
RenderVars.StencilShader = _StencilShader
RenderVars.ScreenCanvas = _ScreenCanvas

--==DevKit Exports==--
DevKit._DrawShader = _DrawShader
DevKit._ImageShader = _ImageShader
DevKit._DisplayShader = _DisplayShader