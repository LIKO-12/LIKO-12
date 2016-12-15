local events = require("Engine.events")

return function(config) --A function that creates a new GPU peripheral.
  
  --Load the config--
  local _LIKO_W, _LIKO_H = config._LIKO_W or 192, config._LIKO_H or 128 --The interal screen width.
  local _LIKO_X, _LIKO_Y = 0,0 --LIKO12 Screen padding in the HOST screen.
  
  local _HOST_W, _HOST_H = love.graphics.getDimensions() --The host window size.
  
  local _GIFSCALE = math.floor(config._GIFSCALE) or 2 --The gif scale factor (must be int).
  local _LIKOScale = math.floor(config._LIKOScale) or 3 --The LIKO12 screen scale to the host screen scale.
  
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
  --End of config loading--
  
  
  local _ShouldDraw = false --This flag means that the gpu has to update the screen for the user.
  
  local _Font = love.graphics.newImageFont(_FontPath, _FontChars, _FontExtraSpacing)
  
  --Hook the resize function--
  events:register("love:resize",function(w,h) --Do some calculations
    _HOST_W, _HOST_H = w, h
    local TSX, TSY = w/_LIKO_W, h/_LIKO_H --TestScaleX, TestScaleY
    if TSX < TSY then
      _LIKO_Scale = TSX
      _LIKO_X, _LIKO_Y = 0, (_HOST_H-_LIKO_H*_LIKOScale)/2
    else
      _LIKO_Scale = TSY
      _LIKO_X, _LIKO_Y = (_HOST_W-_LIKO_W*_LIKOScale)/2, 0
    end
    _ShouldDraw = true
  end)
  
  --Initialize the gpu--
  local _ScreenCanvas = love.graphics.newCanvas(_LIKO_W, _LIKO_H) --Create the screen canvas.
  _ScreenCanvas:setFilter("nearest") --Set the scaling filter to the nearest pixel.
  
  local _GifCanvas = love.graphics.newCanvas(_LIKO_W*_GIFSCALE,_LIKO_H*_GIFSCALE) --Create the gif canvas, used to apply the gif scale factor.
  _GifCanvas:setFilter("nearest") --Set the scaling filter to the nearest pixel.
  
  love.graphics.clear(0,0,0,255) --Clear the host screen.
  
  love.graphics.setCanvas(_ScreenCanvas) --Activate LIKO12 canvas.
  love.graphics.clear(0,0,0,255) --Clear LIKO12 screen for the first time.
  
  event:trigger("love:resize", _HOST_W, _HOST_H) --Calculate LIKO12 scale to the host window for the first time.
  
  love.graphics.setFont(_Font) --Apply the default font.
  
  --Post initialization (Setup the in liko12 gpu settings)--
  
  local ofs = {} --Offsets table.
  ofs.point = {0,0}
  
  --love.graphics.translate(_ScreenTX,_ScreenTY) --Offset all the drawing opereations.
  
  love.graphics.setLineStyle("rough") --Set the line style.
  love.graphics.setLineJoin("miter") --Set the line join style.
  love.graphics.setColor(_GetColor(1))
  
  --api.clear() --Clear the canvas for the first time
  --api.stroke(1) --Set the line width to 1
  
  --Internal Functions--
  function _HostToLiko(x,y) --Convert a position from HOST screen to LIKO12 screen.
    --x, y = x-_ScreenX, y-_ScreenY
    return math.floor(x/_LIKOScale)+1, api.floor(y/_LIKOScale)+1
  end
  
  function _GetColor(c) return _ColorSet[c or 1] or _ColorSet[1] end --Get the (rgba) table of a color id.
  function _GetColorID(r,g,b,a) --Get the color id by the (rgba) table.
    local a = type(a) == "nil" and 255 or a
    for id, col in pairs(_ColorSet) do
      if col[1] == r and col[2] == g and col[3] == b and col[4] == a then
        return id
      end
    end
    return 1
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
    table.insert(ColorStack,GPU.color()) --Add the active color id to the stack.
    return true --It ran successfully.
  end
  
  --Pop the last color from the ColorStack and set it to the active color.
  function GPU.popColor()
    if #ColorStack == 0 then return false, "No more colors to pop." end --Error
    GPU.color(ColorStack[#ColorStack]) --Set the last color in the stack to be the active color.
    table.remove(ColorStack,#ColorStack) --Remove the last color in the stack.
  end
  
  function GPU.clear(c)
    if c and type(c) ~= "number" then return false, "The color id must be a number." end --Error
    if c > 16 or c < 0 then return false, "The color id is out of range." end --Error
    GUI.color(c or 1) --Defaults to black.
    --api.rect(1,1,192,128)
    return true --It ran successfully.
  end
  
  return GPU
end