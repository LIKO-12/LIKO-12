print('hello from Lua');

local imgdata = graphics.newImageData(15, 15);
print(imgdata);
print('dimensions', imgdata:getWidth(), imgdata:getHeight());
imgdata:mapPixels(function(x,y,c)
    return (x + y * imgdata:getWidth()) % 16;
end);

function rand()
    return math.random(0,255)
end

for i = 0, 15 do
    -- screen.setPaletteColor(i, rand(), rand(), rand());
    graphics.rectangle(i * 12, 0, 12, 128, true, i);
    screen.flip();
end

graphics.remapColor(7, 0);
graphics.lines({0,0, 192,128, 64,64}, 7);

local sw, sh = screen.getWidth(), screen.getHeight();

local img = imgdata:toImage();
img:draw(4, 4, 0, 4, 4);

local r = 0
graphics.makeColorOpaque(0)

for i=1,100 do
    r = r + math.pi * 0.02;
    img:draw(sw/2, sh/2, r, 2, 2);
    screen.flip();
end

for eventName, a,b,c,d,e,f in events.pull do
    print(eventName, a,b,c,d,e,f);
end