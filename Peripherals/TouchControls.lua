local events = require("Engine.events")

local onMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

return function(config)
  local CPUKit = config.CPUKit
  if not CPUKit then error("TouchControls Peripheral can't work without the CPUKit passed") end
  
  local GPUKit = config.GPUKit
  if not GPUKit then error("TouchControls Peripheral can't work without the GPUKit passed") end
  
  local alpha = config.alpha or 160
  local fg_alpha = config.fg_alpha or 100
  local bg_alpha = config.bg_alpha or 40
  
  local touchid
  local touchangle
  
  local taid, tbid, tsid
  
  local devkit = {}
  
  devkit.enabled = false
  
  devkit.a_col = GPUKit._GetColor(11)
  devkit.b_col = GPUKit._GetColor(8)
  devkit.start_col = GPUKit._GetColor(12)
  
  devkit.dpad_extra = love.window.toPixels(16)
  devkit.dpad_radius = love.window.toPixels(160/2)
  devkit.dpad_cx = love.window.toPixels(100)
  devkit.dpad_line = math.sin(math.pi/4)*devkit.dpad_radius
  
  devkit.btn_radius = devkit.dpad_radius/2
  devkit.start_w = devkit.dpad_radius*2*0.75
  devkit.start_h = devkit.dpad_radius*0.75*0.75
  devkit.start_x = love.window.toPixels(30) + devkit.dpad_radius/8
  devkit.start_r = devkit.start_h/2
  
  devkit.resize = function(w,h)
    devkit.w = w
    devkit.h = h
    
    if h > w then devkit.protrait = true else devkit.protrait = false end
    
    devkit.b_cx = w - (devkit.dpad_cx-devkit.dpad_radius/2)
    devkit.a_cx = devkit.b_cx - devkit.dpad_radius
    
    if devkit.protrait then
      local likoH = (GPUKit._LIKO_H*(w/GPUKit._LIKO_W))
      devkit.dpad_cy = likoH + (h - likoH)/2
    else
      devkit.dpad_cy = h/2
    end
    
    devkit.b_cy = devkit.dpad_cy
    devkit.a_cy = devkit.b_cy + devkit.dpad_radius
    devkit.start_y = h - (devkit.start_h+devkit.start_x/2)
  end
  
  devkit.resize(love.graphics.getDimensions())
  
  function devkit.isInButton(id,angle)
    if not angle then return false end
    local zero = (math.pi/2)*id
    local astart = zero - math.pi/10
    local aend = zero + math.pi/2 +  math.pi/10
    if astart < 0 then
      return (angle >= math.pi*2+astart or angle <= aend)
    elseif aend > math.pi*2 then
      return (angle >= astart or angle <= aend - math.pi*2)
    else
      return (angle >= astart and angle <= aend)
    end
  end
  
  function devkit.calcDistance(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
  end
  
  function devkit.calcAngle(dy,dx)
    local angle = -math.atan2(dy,dx)
    if angle < 0 then angle = math.pi*2 + angle end
    angle = angle + math.pi/4
    angle = angle%(math.pi*2)
    return angle
  end
  
  devkit.buttons = {false,false,false,false, false,false,false}
  devkit.bmap = {2,3,1,4}
  
  function devkit.updateButtons()
    for i=0,3 do
      if devkit.isInButton(i,touchangle) then
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
  
  local indirect = {}
  local TC = {}
  
  function TC.setInput(bool)
    devkit.enabled = bool
    if onMobile then GPUKit.DevKitDraw(devkit.enabled) end
    return true
  end
  
  events:register("love:resize", devkit.resize)
  
  if not (onMobile or config.onMobile) then return TC, devkit, indirect end
  
  GPUKit.DevKitDraw(devkit.enabled)
  
  --Buttons Touch
  events:register("love:touchpressed",function(id,x,y,dx,dy,p)
    if not taid then
      local dist = devkit.calcDistance(x,y,devkit.a_cx, devkit.a_cy)
      if dist <= devkit.btn_radius then
        taid = id
        devkit.buttons[5] = true
        CPUKit.triggerEvent("touchcontrol",true,5)
        return
      end
    end
    
    if not tbid then
      local dist = devkit.calcDistance(x,y,devkit.b_cx, devkit.b_cy)
      if dist <= devkit.btn_radius then
        tbid = id
        devkit.buttons[6] = true
        CPUKit.triggerEvent("touchcontrol",true,6)
        return
      end
    end
    
    if not tsid then
      if x >= devkit.start_x and x <= devkit.start_x + devkit.start_w then
        if y >= devkit.start_y and devkit.start_y + devkit.start_h then
          tsid = id
          devkit.buttons[7] = true
          CPUKit.triggerEvent("touchcontrol",true,7)
          return
        end
      end
    end
  end)
  
  events:register("love:touchmoved",function(id,x,y,dx,dy,p)
    if taid and taid == id then
      local dist = devkit.calcDistance(x,y,devkit.a_cx, devkit.a_cy)
      if dist <= devkit.btn_radius then
        if not devkit.buttons[5] then
          devkit.buttons[5] = true
          CPUKit.triggerEvent("touchcontrol",true,5)
        end
      else
        if devkit.buttons[5] then
          devkit.buttons[5] = false
          CPUKit.triggerEvent("touchcontrol",false,5)
        end
      end
      
      return
    end
    
    if tbid and tbid == id then
      local dist = devkit.calcDistance(x,y,devkit.b_cx, devkit.b_cy)
      if dist <= devkit.btn_radius then
        if not devkit.buttons[6] then
          devkit.buttons[6] = true
          CPUKit.triggerEvent("touchcontrol",true,6)
        end
      else
        if devkit.buttons[6] then
          devkit.buttons[6] = false
          CPUKit.triggerEvent("touchcontrol",false,6)
        end
      end
      
      return
    end
    
    if tsid and tsid == id then
      if x >= devkit.start_x and x <= devkit.start_x + devkit.start_w and 
      y >= devkit.start_y and devkit.start_y + devkit.start_h then
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
      
      return
    end
  end)
  
  events:register("love:touchreleased",function(id,x,y,dx,dy,p)
    if taid and taid == id then
      taid = nil
      if devkit.buttons[5] then
        devkit.buttons[5] = false
        CPUKit.triggerEvent("touchcontrol",false,5)
      end
      
      return
    end
    
    if tbid and tbid == id then
      tbid = nil
      if devkit.buttons[6] then
        devkit.buttons[6] = false
        CPUKit.triggerEvent("touchcontrol",false,6)
      end
      
      return
    end
    
    if tsid and tsid == id then
      tsid = nil
      if devkit.buttons[7] then
        devkit.buttons[7] = false
        CPUKit.triggerEvent("touchcontrol",false,7)
      end
      
      return
    end
  end)
  
  --Dpad Touch
  events:register("love:touchpressed",function(id,x,y,dx,dy,p)
    if touchid then return end
    local dist = devkit.calcDistance(x,y,devkit.dpad_cx,devkit.dpad_cy)
    if dist > devkit.dpad_radius/3 and dist < devkit.dpad_radius + devkit.dpad_extra then
      touchangle = devkit.calcAngle(y - devkit.dpad_cy, x - devkit.dpad_cx)
      touchid = id
    end
  end)
  
  events:register("love:touchmoved",function(id,x,y,dx,dy,p)
    if (not touchid) or touchid ~= id then return end
    local dist = devkit.calcDistance(x,y,devkit.dpad_cx,devkit.dpad_cy)
    if dist > devkit.dpad_radius/3 and dist < devkit.dpad_radius + devkit.dpad_extra then
      touchangle = devkit.calcAngle(y - devkit.dpad_cy, x - devkit.dpad_cx)
    else
      touchangle = false
    end
    devkit.updateButtons()
  end)
  
  events:register("love:touchreleased",function(id,x,y,dx,dy,p)
    if (not touchid) or touchid ~= id then return end
    touchid = false
    touchangle = false
    devkit.updateButtons()
  end)
  
  events:register("GPU:DevKitDraw",function()
    love.graphics.setLineStyle("smooth")
    --Buttons
    love.graphics.setLineWidth(2)
    --A
    devkit.a_col[4] = bg_alpha; love.graphics.setColor(unpack(devkit.a_col))
    love.graphics.circle("fill",devkit.a_cx, devkit.a_cy, devkit.btn_radius)
    if devkit.buttons[5] then love.graphics.circle("fill",devkit.a_cx, devkit.a_cy, devkit.btn_radius) end
    devkit.a_col[4] = alpha; love.graphics.setColor(unpack(devkit.a_col))
    love.graphics.circle("line",devkit.a_cx, devkit.a_cy, devkit.btn_radius)
    
    --B
    devkit.b_col[4] = bg_alpha; love.graphics.setColor(unpack(devkit.b_col))
    love.graphics.circle("fill",devkit.b_cx, devkit.b_cy, devkit.btn_radius)
    if devkit.buttons[6] then love.graphics.circle("fill",devkit.b_cx, devkit.b_cy, devkit.btn_radius) end
    devkit.b_col[4] = alpha; love.graphics.setColor(unpack(devkit.b_col))
    love.graphics.circle("line",devkit.b_cx, devkit.b_cy, devkit.btn_radius)
    
    --Start
    devkit.start_col[4] = bg_alpha; love.graphics.setColor(unpack(devkit.start_col))
    love.graphics.rectangle("fill",devkit.start_x,devkit.start_y,devkit.start_w,devkit.start_h,devkit.start_r)
    if devkit.buttons[7] then love.graphics.rectangle("fill",devkit.start_x,devkit.start_y,devkit.start_w,devkit.start_h,devkit.start_r) end
    devkit.start_col[4] = alpha; love.graphics.setColor(unpack(devkit.start_col))
    love.graphics.rectangle("line",devkit.start_x,devkit.start_y,devkit.start_w,devkit.start_h,devkit.start_r)
    
    --DPAD
    love.graphics.setLineWidth(2)
    love.graphics.setColor(255,255,255,bg_alpha)
    love.graphics.circle("fill",devkit.dpad_cx, devkit.dpad_cy, devkit.dpad_radius)
    love.graphics.circle("fill",devkit.dpad_cx, devkit.dpad_cy, devkit.dpad_radius/3)
    
    if touchangle then
      if devkit.buttons[1] then
        love.graphics.arc("fill","pie",devkit.dpad_cx, devkit.dpad_cy, devkit.dpad_radius,
          (math.pi/2)*0 - math.pi/4, (math.pi/2)*1 - math.pi/4)
      end
      if devkit.buttons[2] then
        love.graphics.arc("fill","pie",devkit.dpad_cx, devkit.dpad_cy, devkit.dpad_radius,
          (math.pi/2)*3 - math.pi/4, (math.pi/2)*4 - math.pi/4)
      end
      if devkit.buttons[3] then
        love.graphics.arc("fill","pie",devkit.dpad_cx, devkit.dpad_cy, devkit.dpad_radius,
          (math.pi/2)*2 - math.pi/4, (math.pi/2)*3 - math.pi/4)
      end
      if devkit.buttons[4] then
        love.graphics.arc("fill","pie",devkit.dpad_cx, devkit.dpad_cy, devkit.dpad_radius,
          (math.pi/2)*1 - math.pi/4, (math.pi/2)*2 - math.pi/4)
      end
    end
    
    love.graphics.setColor(255,255,255,alpha)
    love.graphics.circle("line",devkit.dpad_cx, devkit.dpad_cy, devkit.dpad_radius)
    
    --Draw the lines
    love.graphics.setLineWidth(1)
    love.graphics.setColor(255,255,255,fg_alpha)
    love.graphics.line(devkit.dpad_cx+devkit.dpad_line, devkit.dpad_cy-devkit.dpad_line,
                       devkit.dpad_cx-devkit.dpad_line, devkit.dpad_cy+devkit.dpad_line)
    
    love.graphics.line(devkit.dpad_cx-devkit.dpad_line, devkit.dpad_cy-devkit.dpad_line,
                       devkit.dpad_cx+devkit.dpad_line, devkit.dpad_cy+devkit.dpad_line)
  end)
  
  return TC, devkit, indirect
end