--This file is responsible about the editors shown after pressing escape--
local flavor = 10 --Orange
local flavorBack = 5 --Brown
local background = 6 --Dark Grey

local swidth, sheight = screenSize()

local function drawUI()
  clear(background) --Clear the screen
  rect(1,1,swidth,8,false,flavor) --Draw the top bar
  rect(sheight-8,1,swidth,8,false,flavor) --Draw the bottom bar
end

return function() --Starts the while loop

end