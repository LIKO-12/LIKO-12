uniform int u_transparent[256]; // array of 0 or 1;
uniform int u_remap[256]; // array of integer values in range [0, 255];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Any shapes/geometry drawing operation would have a texture of a single white pixel (#FFFFFFFF).
    // Any image would have it's blue channel set to 0.0.

    vec4 texture_color = Texel(texture, texture_coords);

    int index = int(color.r * 255.0 + 0.5);

    // Discard transparent pixels for images only.
    if (texture_color.b == 0.0) {
        index = int(texture_color.r * 255.0 + 0.5);

        if (u_transparent[index] == 1) {
            discard;
        }
    }

    // Remap the color.
    index = u_remap[index];

    return vec4(float(index) / 255.0, 1.0, 1.0, 1.0);
}