uniform vec4 u_palette[256];

vec4 effect(vec4 _color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // completely ignore the color field because we don't want to tint the canvas in any way.

    vec4 texture_color = Texel(texture, texture_coords);
    int index = int(texture_color.r * 255.0 + 0.5);

    // Lookup the color from the palette by index.
    vec4 col = u_palette[index];

    // Display grayscale levels for debugging.
    // col = vec4(float(index) / 255.0);
    // col.a = 1.0;

    return col;
}