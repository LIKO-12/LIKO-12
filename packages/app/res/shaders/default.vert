// The default vertex shader used by LÖVE
// https://love2d.org/wiki/love.graphics.newShader

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // The order of operations matters when doing matrix multiplication.
    return transform_projection * vertex_position;
}