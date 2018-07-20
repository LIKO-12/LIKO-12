--luacheck: ignore

local pngData = fs.read("D:/font4x6.png")
local imgData = imagedata(pngData)
local fontData = fontdata(4,6)

imgData:map(function(x,y,c)
 local cb = math.floor(x/5)+1
 x = x%5 -1
 
 if y == 6 or x == -1 or cb == 256 then return end
 
 fontData:setPixel(cb,x,y,(c==7))
end)

fs.write("D:/font4x6.lk12",fontData:encode())

print("done")