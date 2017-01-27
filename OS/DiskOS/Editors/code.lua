local ce = {} --Code editor

local buffer = {} --A table containing lines of code

local screenW, screenH = screenSize()

ce.cx, cy = 1, 1 --Cursor Position
ce.tw, ce.th = termSize() --The terminal size
ce.th = ce.th-2 --Because of the top and bottom bars
ce.vx, ce.vy = 1,1 --View postions

--Check the position of the cursor so the view includes it
function ce:checkPos()
  --X position checking--
  if self.cx > self.tw + (self.vx-1) then --Passed the screen to the right
    self.vx = self.cx - (self.tw-1)
  elseif self.cx < self.vx then --Passed the screen to the left
    self.vx = self.cx
  end
  
  --Y position checking--
  if self.cy > #buffer then self.cy = #buffer end --Passed the end of the file
  
  if self.cy > self.th + self.vy-1 then --Passed the screen to the bottom
    self.vy = self.cy - (self.th-1)
  elseif self.cy < self.vy then --Passed the screen to the top
    if self.cy < 1 then
      self.cy = 1
    else
      self.vy = self.cy
    end
  end
end

--Draw the code on the screen
function ce:drawBuffer()
  
end

function ce:entered()
  
end

function ce:leaved()
  
end



return ce