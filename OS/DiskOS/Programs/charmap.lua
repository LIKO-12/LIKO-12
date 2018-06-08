if select(1,...) == "-?" then
  printUsage(
    "charmap","Displays LIKO-12 Extended ASCII Characters Map."
  )
  return
end

clear() printCursor(0,0,0)

local tohex = bit.tohex
local counter = 0

for i=128, 255 do
 if counter == 7 then print("") counter = 0 end
 counter = counter + 1
 color(6) print(tohex(i,2):upper(),false)
 color(5) print(":",false)
 color(7) print(string.char(i).." ",false)
end