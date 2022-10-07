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
    screen.setPaletteColor(i, rand(), rand(), rand());
    graphics.rectangle(i * 12, 0, 12, 128, true, i);
    screen.flip();
end

graphics.remapColor(7, 0);
graphics.lines({0,0, 192,128, 64,64}, 7);

function drawImageData(id)
    local w = id:getWidth();
    local h = id:getHeight();

    for x=0,w-1 do
        for y=0,h-1 do
            graphics.rectangle(x*4+5, y*4+5, 4, 4, true, id:getPixel(x,y));
        end
    end
end

drawImageData(imgdata);

for eventName, a,b,c,d,e,f in events.pull do
    print(eventName, a,b,c,d,e,f);
end