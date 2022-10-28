print('hello from Lua');

local imgdata = liko.graphics.newImageData(15, 15);
print(imgdata);
print('dimensions', imgdata:getWidth(), imgdata:getHeight());
imgdata:mapPixels(function(x,y,c)
    return (x + y * imgdata:getWidth()) % 16;
end);

function rand()
    return math.random(0,255)
end

for i = 0, 15 do
    -- liko.screen.setPaletteColor(i, rand(), rand(), rand());
    liko.graphics.rectangle(i * 12, 0, 12, 128, true, i);
    liko.screen.flip();
end

liko.graphics.remapColor(7, 0);
liko.graphics.lines({0,0, 192,128, 64,64}, 7);

local sw, sh = liko.screen.getWidth(), liko.screen.getHeight();

local img = imgdata:toImage();
img:draw(4, 4, 0, 4, 4);

local r = 0
liko.graphics.makeColorOpaque(0)

for i=1,100 do
    r = r + math.pi * 0.02;
    img:draw(sw/2, sh/2, r, 2, 2);
    liko.screen.flip();
end

for eventName, a,b,c,d,e,f in liko.events.pull do
    print(eventName, a,b,c,d,e,f);
end