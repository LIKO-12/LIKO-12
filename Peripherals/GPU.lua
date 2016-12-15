local events = require("Engine.events")

return function(config) --A function that creates a new GPU peripheral.
  
  --Load the config--
  local _LIKO_W, _LIKO_H = config._LIKO_W or 192, config._LIKO_H or 128 --LIKO screen width.
  local _LIKO_X, _LIKO_Y = 0,0 --LIKO12 Screen padding in the HOST screen.
  
  local _HOST_W, _HOST_H = love.graphics.getDimensions() --The host window size.
  
  local _GIFSCALE = math.floor(config._GIFSCALE or 2) --The gif scale factor (must be int).
  local _LIKOScale = math.floor(config._LIKOScale or 3) --The LIKO12 screen scale to the host screen scale.
  
  local _FontChars = config._FontChars or 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"\'`-_/1234567890!?[](){}.,;:<>+=%#^*~ ' --Font chars
  local _FontPath, _FontExtraSpacing = config._FontPath or "/Engine/font.png", config._FontExtraSpacing or 1 --Font image path, and how many extra spacing pixels between every character.
  
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
  --End of config loading--
  
  
  local _ShouldDraw = false --This flag means that the gpu has to update the screen for the user.
  
  local _Font = love.graphics.newImageFont(_FontPath, _FontChars, _FontExtraSpacing)
  
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
  local _ScreenCanvas = love.graphics.newCanvas(_LIKO_W, _LIKO_H) --Create the screen canvas.
  _ScreenCanvas:setFilter("nearest") --Set the scaling filter to the nearest pixel.
  
  local _GifCanvas = love.graphics.newCanvas(_LIKO_W*_GIFSCALE,_LIKO_H*_GIFSCALE) --Create the gif canvas, used to apply the gif scale factor.
  _GifCanvas:setFilter("nearest") --Set the scaling filter to the nearest pixel.
  
  love.graphics.clear(0,0,0,255) --Clear the host screen.
  
  love.graphics.setCanvas(_ScreenCanvas) --Activate LIKO12 canvas.
  love.graphics.clear(0,0,0,255) --Clear LIKO12 screen for the first time.
  
  events:trigger("love:resize", _HOST_W, _HOST_H) --Calculate LIKO12 scale to the host window for the first time.
  
  love.graphics.setFont(_Font) --Apply the default font.
  
  --Post initialization (Setup the in liko12 gpu settings)--
  
  local ofs = {} --Offsets table.
  ofs.screen = {0,0} --The offset of all the drawing opereations.
  ofs.point = {-1,0} --The offset of GPU.point/s.
  ofs.line = {0,0} --The offset of GPU.line/s.
  ofs.rect = {-1,-1} --The offset of GPU.rect with l as false.
  ofs.rectSize = {0,0} --The offset of w,h in GPU.rect with l as false.
  ofs.rect_line = {0,0} --The offset of GPU.rect with l as true.
  ofs.rectSize_line = {-1,-1} --The offset of w,h in GPU.rect with l as false.
  
  love.graphics.translate(unpack(ofs.screen)) --Offset all the drawing opereations.
  
  --Internal Functions--
  local function _HostToLiko(x,y) --Convert a position from HOST screen to LIKO12 screen.
    --x, y = x-_ScreenX, y-_ScreenY
    return math.floor(x/_LIKOScale)+1, api.floor(y/_LIKOScale)+1
  end
  
  local function _GetColor(c) return _ColorSet[c or 1] or _ColorSet[1] end --Get the (rgba) table of a color id.
  local function _GetColorID(r,g,b,a) --Get the color id by the (rgba) table.
    local a = type(a) == "nil" and 255 or a
    for id, col in pairs(_ColorSet) do
      if col[1] == r and col[2] == g and col[3] == b and col[4] == a then
        return id
      end
    end
    return 1
  end
  
  local function exe(...) --Excute a LIKO12 api function (to handle errors)
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
  
  --The api starts here--
  local GPU = {}
  
  local ColorStack = {} --The colors stack (pushColor,popColor)
  
  --Call with color id to set the active color.
  --Call with no args to get the current acive color id.
  function GPU.color(id)
    if id then
      if type(id) ~= "number" then return false, "The color id must be a number." end --Error
      if id > 16 or id < 0 then return false, "The color id is out of range." end --Error
      id = math.floor(id) --Remove the float digits.
      love.graphics.setColor(_GetColor(id)) --Set the active color.
      return true --It ran successfuly.
    else
      return true, _GetColorID(love.graphics.getColor()) --Return the current color.
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
  
  --Draw a rectangle filled, or lines only.
  --X pos, Y pos, W width, H height, L linerect, C colorid.
  function GPU.rect(x,y,w,h,l,c)
    local x,y,w,h,l,c = x or 1, y or 1, w or 1, h or 1, l or false, c --In case if they are not provided.
    
    --It accepts all the args as a table.
    if x and type(x) == "table" then
      x,y,w,h,l,c = unpack(x)
    end
    
    --Args types verification
    if type(x) ~= "number" then return false, "X pos must be a number or nil." end --Error
    if type(y) ~= "number" then return false, "Y pos must be a number or nil." end --Error
    if type(w) ~= "number" then return false, "W width must be a number or nil." end --Error
    if type(h) ~= "number" then return false, "H height must be a number or nil." end --Error
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
  
  --Clears the whole screen with black or the given color id.
  function GPU.clear(c)
    local c = c or 1
    if type(c) ~= "number" then return false, "The color id must be a number." end --Error
    if c > 16 or c < 0 then return false, "The color id is out of range." end --Error
    exe(GPU.rect(1,1,192,128,false,c or 1)) --Draw a rectangle that covers the whole screen.
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
    for k,v in ipairs(args) do if (k % 2 == 0) then args[k] = v + ofs.line[2] else args[k] = v + ofs.line[1] end end --Apply the offset.
    love.graphics.line(unpack(args)) _ShouldDraw = true --Draw the lines and tell that changes has been made.
    exe(GPU.popColor()) --Pop the last color in the stack.
    return true --It ran successfully.
  end
  GPU.line = GPU.lines --Just an alt name :P.
  
  --End of API--
  
  love.graphics.setLineStyle("rough") --Set the line style.
  love.graphics.setLineJoin("miter") --Set the line join style.
  love.graphics.setPointSize(1) --Set the point size to 1px.
  love.graphics.setLineWidth(1) --Set the line width to 1px.
  love.graphics.setColor(_GetColor(1)) --Set the active color to black.
  
  exe(GPU.clear()) --Clear the canvas for the first time.
  
  --Host to love.run when graphics is active--
  events:register("love:graphics",function()
    if _ShouldDraw then --When it's required to draw (when changes has been made to the canvas)
      love.graphics.setCanvas() --Quit the canvas and return to the host screen.
      love.graphics.origin() --Reset all transformations.
      
      GPU.pushColor() --Push the current color to the stack.
      love.graphics.setColor(255,255,255,255) --I don't want to tint the canvas :P
      
      if _ClearOnRender then love.graphics.clear(0,0,0,255) end --Clear the screen (Some platforms are glitching without this).
      
      love.graphics.draw(_ScreenCanvas, _LIKO_X, _LIKO_Y, 0, _LIKOScale, _LIKOScale) --Draw the canvas.
      
      love.graphics.present() --Present the screen to the host & the user.
      love.graphics.setCanvas(_ScreenCanvas) --Reactivate the canvas.
      love.graphics.translate(unpack(ofs.screen)) --Reapply the offset.
      _ShouldDraw = false --Reset the flag.
      GPU.popColor() --Restore the active color.
    end
  end)
  
  return GPU --Return the table containing all of the api functions.
end