local events = require("Engine.events")

local onMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

--Wrapper for setColor to use 0-255 values
local function setColor(r,g,b,a)
  if type(r) == "table" then
    r,g,b,a = r[1], r[2], r[3], r[4]
  end
  if r then r = r/255 end
  if g then g = g/255 end
  if b then b = b/255 end
  if a then a = a/255 end
  
  love.graphics.setColor(r, g, b, a)
end

return function(config)
  local CPUKit = config.CPUKit
  if not CPUKit then error("TouchControls Peripheral can't work without the CPUKit passed") end
  
  local GPUKit = config.GPUKit
  if not GPUKit then error("TouchControls Peripheral can't work without the GPUKit passed") end
  
  --Three levels of alpha
  local alpha = config.alpha or 160 --The dpad outline
  local fg_alpha = config.fg_alpha or 100 --The dpad lines
  local bg_alpha = config.bg_alpha or 40 --The dpad background
  
  local devkit = {}
  
  local ControlsEnabled = false
  
  --DPAD Variables
  local dpad_radius = 160/2 --The radius of the depad circle
  local dpad_extra = 16 --The extra detection zone around the dpad
  local dpad_cx, dpad_cy = 100 --The dpad center position
  local dpad_line = math.sin(math.pi/4)*dpad_radius --The position of a point in pi/4 (For the cross line to draw)
  local touchangle --Touch variable
  
  --A Button
  local a_col = GPUKit._GetColor(11) --The color of the A button
  local a_cx, a_cy --The center of the A button circle
  
  --B Button
  local b_col = GPUKit._GetColor(8) --The color of the B button
  local b_cx, b_cy --The center of the B button circle
  
  --Start Button
  local start_col = GPUKit._GetColor(12) --The color of the Start button
  local start_w, start_h = dpad_radius*2*0.75, dpad_radius*0.75*0.75 --The size of the Start button rectangle
  local start_x, start_y = 30 + dpad_radius/8 --The position of the Start button
  local start_r = start_h/2 --The radius of the Start button corners
  
  --All Buttons (Shared)
  local btn_radius = dpad_radius/2 --The radius of button A and B circles
  local touchids = {} --1,2,3,4 for dpad (only 1 is used), 5,6,7 for other buttons
  
  local protrait --Is the device in protrait orientation
  
  devkit.resize = function(w,h)
    if h > w then protrait = true else protrait = false end --Detect if the device is in protrait.
    
    b_cx = w - (dpad_cx-dpad_radius/2) --Calculate the button B center X coord.
    a_cx = b_cx - dpad_radius --Calculate the button A center X coord.
    
    --Better button position when in protrait
    if protrait then
      local likoH = (GPUKit._LIKO_H*(w/GPUKit._LIKO_W)) --The LIKO-12 screen size.
      dpad_cy = likoH + (h - likoH)/2 --Calculate the dpad center Y coord.
    else
      dpad_cy = h/2 --Calculate the dpad center Y coord.
    end
    
    b_cy = dpad_cy --Calculate the button B center Y coord
    a_cy = b_cy + dpad_radius --Calculate the button A center Y coord
    start_y = h - (start_h+start_x/2) --Calculate the Start button Y coord
  end
  
  devkit.resize(love.graphics.getDimensions()) --Calculate the positions for the first time.
  
  events.register("love:resize", devkit.resize) --Register the resize event.
  
  local function isDpadPressed(id,angle)
    if not angle then return false end --If the user is not touching the dpad, then all buttons are not pressed
    local zero = (math.pi/2)*id
    local astart = zero - math.pi/10 --The start angle
    local aend = zero + math.pi/2 +  math.pi/10 --The end angle
    if astart < 0 then
      return (angle >= math.pi*2+astart or angle <= aend)
    elseif aend > math.pi*2 then
      return (angle >= astart or angle <= aend - math.pi*2)
    else
      return (angle >= astart and angle <= aend)
    end
  end
  
  --Calculates the distance between 2 points
  local function calcDistance(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
  end
  
  --Calculates the angle of a touch in dpad circle
  local function calcAngle(dy,dx)
    local angle = -math.atan2(dy,dx)
    if angle < 0 then angle = math.pi*2 + angle end
    angle = angle + math.pi/4
    angle = angle%(math.pi*2)
    return angle
  end
  
  --The buttons memory
  devkit.buttons = {false,false,false,false, false,false,false}
  devkit.bmap = {2,3,1,4} --Remap the dpad buttons ids to their real numbers.
  
  --Update dpad buttons.
  local function updateDpad()
    for i=0,3 do
      if isDpadPressed(i,touchangle) then
        if not devkit.buttons[i+1] then
          CPUKit.triggerEvent("touchcontrol",true,devkit.bmap[i+1])
          devkit.buttons[i+1] = true
        end
      else
        if devkit.buttons[i+1] then
          CPUKit.triggerEvent("touchcontrol",false,devkit.bmap[i+1])
          devkit.buttons[i+1] = false
        end
      end
    end
  end
  
  local function updateButtons(tid,state,tx,ty)
    for id=5, 7 do
      if id < 7 then --The AB buttons
        local cx, cy; if id == 5 then cx,cy = a_cx, a_cy else cx,cy = b_cx, b_cy end
        local dist = calcDistance(tx,ty,cx, cy)
        
        if state == "pressed" and not touchids[id] then
          if dist <= btn_radius then
            touchids[id] = tid
            devkit.buttons[id] = true
            CPUKit.triggerEvent("touchcontrol",true,id)
          end
        elseif state == "moved" and touchids[id] and touchids[id] == tid then
          if dist <= btn_radius then
            if not devkit.buttons[id] then
              devkit.buttons[id] = true
              CPUKit.triggerEvent("touchcontrol",true,id)
            end
          else
            if devkit.buttons[id] then
              devkit.buttons[id] = false
              CPUKit.triggerEvent("touchcontrol",false,id)
            end
          end
        elseif state == "released" and touchids[id] and touchids[id] == tid then
          touchids[id] = false
          if devkit.buttons[id] then
            devkit.buttons[id] = false
            CPUKit.triggerEvent("touchcontrol",false,id)
          end
        end
      else --The start button
        if state == "pressed" and not touchids[id] then
          if tx >= start_x and tx <= start_x + start_w then
            if ty >= start_y and ty <= start_y + start_h then
              touchids[id] = tid
              devkit.buttons[7] = true
              CPUKit.triggerEvent("touchcontrol",true,7)
              return
            end
          end
        elseif state == "moved" and touchids[id] and touchids[id] == tid then
          if tx >= start_x and tx <= start_x + start_w and ty >= start_y and ty <= start_y + start_h then
            if not devkit.buttons[7] then
              devkit.buttons[7] = true
              CPUKit.triggerEvent("touchcontrol",true,7)
            end
          else
            if devkit.buttons[7] then
              devkit.buttons[7] = false
              CPUKit.triggerEvent("touchcontrol",false,7)
            end
          end
        elseif state == "released" and touchids[id] and touchids[id] == tid then
          touchids[id] = nil
          if devkit.buttons[7] then
            devkit.buttons[7] = false
            CPUKit.triggerEvent("touchcontrol",false,7)
          end
        end
      end
    end
  end
  
  local function drawButtons()
    for id=5, 7 do
      love.graphics.setLineWidth(devkit.buttons[id] and 2 or 1)
      if id < 7 then --AB buttons
        local cx, cy, col; if id == 5 then cx,cy,col = a_cx,a_cy,a_col  else cx,cy,col = b_cx,b_cy,b_col end
        col[4] = bg_alpha; setColor(col)
        love.graphics.circle("fill",cx, cy, btn_radius)
        if devkit.buttons[id] then love.graphics.circle("fill",cx, cy, btn_radius) end
        col[4] = alpha; setColor(col)
        love.graphics.circle("line",cx, cy, btn_radius)
      else --Start button
        start_col[4] = bg_alpha; setColor(start_col)
        love.graphics.rectangle("fill",start_x,start_y,start_w,start_h,start_r)
        if devkit.buttons[7] then love.graphics.rectangle("fill",start_x,start_y,start_w,start_h,start_r) end
        start_col[4] = alpha; setColor(start_col)
        love.graphics.rectangle("line",start_x,start_y,start_w,start_h,start_r)
      end
    end
  end
  
  local TC, yTC = {}, {}
  
  --Toggle the touch controls
  function TC.setInput(bool)
    ControlsEnabled = bool
    if onMobile then GPUKit.DevKitDraw(ControlsEnabled) end
  end
  
  --Buttons Touch
  events.register("love:touchpressed",function(id,x,y,dx,dy,p) updateButtons(id,"pressed",x,y) end)
  events.register("love:touchmoved",function(id,x,y,dx,dy,p) updateButtons(id,"moved",x,y) end)
  events.register("love:touchreleased",function(id,x,y,dx,dy,p) updateButtons(id,"released",x,y) end)
  
  --Dpad Touch
  events.register("love:touchpressed",function(id,x,y,dx,dy,p)
    if touchids[1] then return end
    local dist = calcDistance(x,y,dpad_cx,dpad_cy)
    if dist < dpad_radius + dpad_extra then
      touchangle = calcAngle(y - dpad_cy, x - dpad_cx)
      touchids[1] = id
      updateDpad()
    end
  end)
  
  events.register("love:touchmoved",function(id,x,y,dx,dy,p)
    if (not touchids[1]) or touchids[1] ~= id then return end
    
    touchangle = calcAngle(y - dpad_cy, x - dpad_cx)
    updateDpad()
  end)
  
  events.register("love:touchreleased",function(id,x,y,dx,dy,p)
    if (not touchids[1]) or touchids[1] ~= id then return end
    touchids[1] = false
    touchangle = false
    updateDpad()
  end)
  
  events.register("GPU:DevKitDraw",function()
    love.graphics.setLineStyle("smooth")
    --Buttons
    drawButtons()
    
    --DPAD
    love.graphics.setLineWidth(1)
    setColor(255,255,255,bg_alpha)
    love.graphics.circle("fill",dpad_cx, dpad_cy, dpad_radius)
    
    if touchangle then
      if devkit.buttons[1] then
        love.graphics.arc("fill","pie",dpad_cx, dpad_cy, dpad_radius,
          (math.pi/2)*0 - math.pi/4, (math.pi/2)*1 - math.pi/4)
      end
      if devkit.buttons[2] then
        love.graphics.arc("fill","pie",dpad_cx, dpad_cy, dpad_radius,
          (math.pi/2)*3 - math.pi/4, (math.pi/2)*4 - math.pi/4)
      end
      if devkit.buttons[3] then
        love.graphics.arc("fill","pie",dpad_cx, dpad_cy, dpad_radius,
          (math.pi/2)*2 - math.pi/4, (math.pi/2)*3 - math.pi/4)
      end
      if devkit.buttons[4] then
        love.graphics.arc("fill","pie",dpad_cx, dpad_cy, dpad_radius,
          (math.pi/2)*1 - math.pi/4, (math.pi/2)*2 - math.pi/4)
      end
    end
    
    setColor(255,255,255,alpha)
    love.graphics.circle("line",dpad_cx, dpad_cy, dpad_radius)
    
    --Draw the lines
    love.graphics.setLineWidth(0.5)
    setColor(255,255,255,fg_alpha)
    love.graphics.line(dpad_cx+dpad_line, dpad_cy-dpad_line,
                       dpad_cx-dpad_line, dpad_cy+dpad_line)
    
    love.graphics.line(dpad_cx-dpad_line, dpad_cy-dpad_line,
                       dpad_cx+dpad_line, dpad_cy+dpad_line)
  end)
  
  return TC, yTC, devkit
end