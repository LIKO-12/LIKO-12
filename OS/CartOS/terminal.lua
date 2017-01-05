--The terminal !--
local path = "C://Programs/;"
local curdir = "C://"

local function nextPath(p)
  if p:sub(-1)~=";" then p=p..";" end
  return p:gmatch("(.-);")
end

printCursor(1,1,1)
color(9) print("LIKO-12 V0.6.0 DEV")
color(8) print("CartOS DEV B1")
color(7) print("\nA PICO-8 CLONE OS FOR LIKO-12 WITH EXTRA ABILITIES")
color(10) print("TYPE HELP FOR HELP")
