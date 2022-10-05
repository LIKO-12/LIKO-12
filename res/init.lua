print('hello from Lua');

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

print(coroutine.running());

for eventName, a,b,c,d,e,f in events.pull do
    print(eventName, a,b,c,d,e,f);
end