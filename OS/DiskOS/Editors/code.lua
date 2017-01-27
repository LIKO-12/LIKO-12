local ce = {} --Code editor

local buffer = {} --A table containing lines of code

local screenW, screenH = screenSize()
local lume = require("C://Libraries/lume")
local clua = require("C://Libraries/colorize_lua")
local cluacolors = {
text = 8,
keyword = 11,
number = 13,
comment = 14,
str = 13
}

ce.bkc = 6--Background Color
ce.cx, cy = 1, 1 --Cursor Position
ce.tw, ce.th = termSize() --The terminal size
ce.th = ce.th-2 --Because of the top and bottom bars
ce.vx, ce.vy = 1,1 --View postions

--A usefull print function with color support !
function ce:colorPrint(tbl,gx,gy)
  pushColor()
  for i=1, #tbl, i=i+2 do
    local col = tbl[i]
    local txt = tbl[i+1]
    color(col)
    print(txt,_,true)--Disable auto newline
  end
  print("")--A new line
  popColor()
end

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
  local cbuffer = clua(lume.clone(lume.slice(buffer,self.shy,self.shy+self.th)),cluacolors)
  rect(1,9,screenW,screenH-8*2,false,self.bkc)
  for k, l in ipairs(cbuffer) do
    printCursor(-(self.shx-1),k+1,0)
    self:colorPrint(l)
  end
end

function ce:entered()
  
end

function ce:leaved()
  
end



return ce