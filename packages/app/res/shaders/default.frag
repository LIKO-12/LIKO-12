// The default fragment shader used by LÖVE
// https://love2d.org/wiki/love.graphics.newShader

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texture_color = Texel(texture, texture_coords);
    return texture_color * color;
}