love.load = () => {
    print('Hello from TypeScript!');
    love.graphics.setBackgroundColor(0.5, 0, 0.5, 1);
}

love.draw = () => {
    love.graphics.setColor(1, 1, 1, 1);
    love.graphics.print('Hello', 20, 20);
}