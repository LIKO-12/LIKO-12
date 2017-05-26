print("")
local data = clipboard()
data = math.b64dec(data)
data = math.decompress(data,"lz4")
fs.write("C://gdebugclip.lk12",data)
--color(12) print("Saved debug image successfully")
clear(0)
local img = image(data)

local sw,sh = screenSize()

for event in pullEvent do
 if event == "update" then
  clear(0)
  img:draw(0,0)
  local mx,my = getMPos()
  point(mx,my ,10)
  color(7) print(mx..","..my,4,sh-9)
 end
 if event == "keypressed" then return end
end