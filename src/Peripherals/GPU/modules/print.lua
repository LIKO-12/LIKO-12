--GPU: Printing.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local lg = love.graphics

local utf8 = require("utf8")

local Path = GPUVars.Path
local WindowVars = GPUVars.Window
local SharedVars = GPUVars.Shared
local CalibrationVars = GPUVars.Calibration
local VRamVars = GPUVars.VRam
local RenderVars = GPUVars.Render

--==Localized Lua Library==--
local strByte = string.byte
local strChar = string.char

local utf8Char = utf8.char
local utf8Len = utf8.len

--==Varss Constants==--
local _LIKO_W, _LIKO_H = WindowVars.LIKO_W, WindowVars.LIKO_H
local Verify = SharedVars.Verify
local ofs = CalibrationVars.Offsets
local UnbindVRAM = VRamVars.UnbindVRAM

--==Local Functions==--
local function escapeASCIIGSub(char)
  return utf8Char(strByte(char))
end

local function escapeASCII(str)
  return string.gsub(str,"[\x80-\xFF]",escapeASCIIGSub)
end

--==Local Variables==--

local _FontW, _FontH = Config._FontW or 4, Config._FontH or 6 --Font character size
  
local _FontChars = {} --Font chars
for i=1,255 do _FontChars[i] = strChar(i) end
_FontChars = escapeASCII(table.concat(_FontChars))

local _FontPath, _FontExtraSpacing = Config._FontPath or Path.."fonts/font4x6.png", Config._FontExtraSpacing or 1 --Font image path, and how many extra spacing pixels between every character.

local _Font = lg.newImageFont(_FontPath, _FontChars, _FontExtraSpacing) --Create the default liko12 font.

lg.setFont(_Font) --Activate the default font.

local printCursor = {x=0,y=0,bgc=0} --The print grid cursor pos.
local TERM_W, TERM_H = math.floor(_LIKO_W/(_FontW+1)), math.floor(_LIKO_H/(_FontH+1)) --The size of characters that the screen can fit.

--==GPU Printing Dimensions API==--

function GPU.termSize() return TERM_W, TERM_H end
function GPU.termWidth() return TERM_W end
function GPU.termHeight() return TERM_H end
function GPU.fontSize() return _FontW, _FontH end
function GPU.fontWidth() return _FontW end
function GPU.fontHeight() return _FontH end

--==GPU Printing API==--

--Sets the position of the printing corsor when x,y are supplied
--Or returns the current position of the printing cursor when x,y are not supplied
function GPU.printCursor(x,y,bgc)
  if x or y or bgc then
    x, y = x or printCursor.x, y or printCursor.y
    bgc = bgc or printCursor.bgc
    
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
  t = tostring(t) --Make sure it's a string
  t = escapeASCII(t)
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
      lg.printf(t,x+ofs.print[1],y+ofs.print[2],limit,align,r,sx,sy,ox,oy,kx,ky) RenderVars.ShouldDraw = true
    else
      lg.print(t,x+ofs.print[1],y+ofs.print[2],r,sx,sy,ox,oy,kx,ky) RenderVars.ShouldDraw = true
    end
  else --Print to terminal pos
    local pc = printCursor --Shortcut
    
    local function togrid(gx,gy) --Covert to grid cordinates
      return math.floor(gx*(_FontW+1)), math.floor(gy*(_FontH+1))
    end
    
    --A function to draw the background rectangle
    local function drawbackground(gx,gy,gw)
      if pc.bgc == -1 or gw < 1 then return end --No need to draw the background
      gx,gy = togrid(gx,gy)
      GPU.rect(gx,gy, gw*(_FontW+1)+1,_FontH+2, false, pc.bgc)
    end
    
    --Draw directly without formatting nor updating the cursor pos.
    if y then
      drawbackground(pc.x, pc.y, t:len()) --Draw the background.
      local gx,gy = togrid(pc.x, pc.y)
      lg.print(t,gx+1+ofs.print_grid[1],gy+1+ofs.print_grid[2]) --Print the text.
      pc.x = pc.x + utf8Len(t) --Update the x pos
      return true --It ran successfully
    end
    t = t.."\n"
    if type(x) == "nil" or x then t = t .. "\n" end --Auto newline after printing.
    
    local sw = TERM_W*(_FontW+1) --Screen width
    local pre_spaces = string.rep(" ", pc.x) --The pre space for text wrapping to calculate
    local _, wrappedText = _Font:getWrap(pre_spaces..t, sw) --Get the text wrapped
    local linesNum = #wrappedText --Number of lines
    if linesNum > TERM_H-pc.y then --It will go down of the screen, so shift the screen up.
      GPU.pushPalette() GPU.palt() GPU.pal() --Backup the palette and reset the palette.
      local extra = linesNum - (TERM_H-pc.y) --The extra lines that will draw out of the screen.
      local sc = GPU.screenshot() --Take a screenshot
      GPU.clear(0) --Clear the screen
      sc:image():draw(0, -extra*(_FontH+1)) --Draw the screen shifted up
      pc.y = pc.y-extra --Update the cursor pos.
      GPU.popPalette() --Restore the palette.
    end
    
    local drawY = pc.y
    
    --Iterate over the lines.
    for k, line in ipairs(wrappedText) do
      local printX = 0
      if k == 1 then line = line:sub(pre_spaces:len()+1,-1); printX = pc.x end --Remove the pre_spaces
      local linelen = utf8Len(line) --The line length
      drawbackground(printX,pc.y,linelen) --Draw the line background
      
      --Update the cursor pos
      pc.x = printX + utf8Len(line)
      if wrappedText[k+1] then pc.y = pc.y + 1 end --If there's a next line
    end
    
    lg.printf(pre_spaces..t,1+ofs.print_grid[1],drawY*(_FontH+1)+1+ofs.print_grid[2],sw) RenderVars.ShouldDraw = true --Print the text
  end
end

local function _wrapText(arg1, arg2, ...)
  if arg1 then return arg2, ...
  else error(tostring(args2, 3)) end
end

function GPU.wrapText(text,sw)
  return _wrapText(pcall(_Font.getWrap,_Font,text, sw))
end

function GPU.printBackspace(c,skpCr) UnbindVRAM()
  c = c or printCursor.bgc
  c = Verify(c,"Color","number",true)
  local function cr() local s = GPU.screenshot():image() GPU.clear() s:draw(1,_FontH+1) end
  
  local function togrid(gx,gy) --Covert to grid cordinates
    return math.floor(gx*(_FontW+1)), math.floor(gy*(_FontH+1))
  end
  
  --A function to draw the background rectangle
  local function drawbackground(gx,gy,gw)
    if c == -1 or gw < 1 then return end --No need to draw the background
    gx,gy = togrid(gx,gy)
    GPU.rect(gx,gy, gw*(_FontW+1)+1,_FontH+2, false, c)
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

--==DevKit Exports==--
DevKit._FontChars = _FontChars