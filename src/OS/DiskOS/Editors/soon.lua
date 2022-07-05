--This is an editor to show a "COMING SOON" screen.
local eapi = (...)

local soon = {}

local sw, sh = screenSize()
local tw, th = termSize()
local str = "WORK IN PROGRESS..."
local strlen = str:len()-3
local tx = math.floor((tw-strlen)/2)
local ty = math.floor(th/2)

function soon:entered()
  eapi:drawUI()
  rect(0,8,sw,sh-16,false,0)
  color(7)
  printCursor(tx-1,ty-1,-1)
  print(str)
end

return soon
