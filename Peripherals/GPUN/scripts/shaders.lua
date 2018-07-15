--This file contains the shaders used by the LIKO-12 GPU.
--Note: Those are modified version of picolove shaders.

local shaders = {}

function shaders.newShader(precode,postcode,transcode,vec4)
  if transcode then
    local ok, shader
    if vec4 then
      ok, shader = pcall(love.graphics.newShader,precode.."vec4 col=palette[index]/255.0;\n  float coltrans=transparent[index]*ta;"..postcode)
    else
      ok, shader = pcall(love.graphics.newShader,precode.."float col=palette[index]/255.0;\n  float coltrans=transparent[index]*ta;"..postcode)
    end
    
    if not ok then
      print("Failed with normal shader, attemping to patch non deterministic index ...")
      local data = precode
      if vec4 then
        data = data .."vec4 col;\n  "
      else
        data = data .."float col;\n  "
      end
      
      data = data.. "if(index == 0) col = palette[0] / 255.0;"
      for i=1, 14 do
        data = data .. "\n  else if(index == "..i..") col = palette["..i.."] / 255.0;"
      end
      data = data .. "\n  else col = palette[15] / 255.0;\n  float coltrans;\n  "
      
      data = data.. "if(index == 0) coltrans = transparent[0]*ta;"
      for i=1, 14 do
        data = data .. "\n  else if(index == "..i..") coltrans = transparent["..i.."]*ta;"
      end
      data = data .. "\n  else coltrans = transparent[15]*ta;\n" .. postcode
      
      return love.graphics.newShader(data)
    end
    return shader
  ----------------------------------------------------------------
  elseif postcode then
    local ok, shader
    if vec4 then
      ok, shader = pcall(love.graphics.newShader,precode.."vec4 col=palette[index]/255.0;"..postcode)
    else
      ok, shader = pcall(love.graphics.newShader,precode.."float col=palette[index]/255.0;"..postcode)
    end
    
    if not ok then
      print("Failed with normal shader, attemping to patch non deterministic index ...")
      local data = precode
      if vec4 then
        data = data .."vec4 col;\n  "
      else
        data = data .."float col;\n  "
      end
      data = data.. "if(index == 0) col = palette[0] / 255.0;"
      for i=1, 14 do
        data = data .. "\n  else if(index == "..i..") col = palette["..i.."] / 255.0;"
      end
      data = data .. "\n  else col = palette[15] / 255.0;\n" .. postcode
      
      return love.graphics.newShader(data)
    end
    return shader
  ----------------------------------------------------------------
  else
    return love.graphics.newShader(precode)
  end
end

--The draw palette shader
shaders.drawShader = shaders.newShader([[
extern float palette[16];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  int index=int(color.r*255.0+0.5);
  float ta=float(Texel(texture,texture_coords).a);
  ]],[[
  return vec4(col, 0.0, 0.0, color.a*ta);
}]])

--The image:draw palette shader
shaders.imageShader = shaders.newShader([[
extern float palette[16];
extern float transparent[16];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  int index=int(Texel(texture, texture_coords).r*255.0+0.5);
  float ta=float(Texel(texture,texture_coords).a);
  ]],[[
  return vec4(col, 0.0, 0.0, coltrans);
}]],true)

--The final display shader.
shaders.displayShader = shaders.newShader([[
  extern vec4 palette[16];
  
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    int index=int(Texel(texture, texture_coords).r*255.0+0.5);
    float ta=float(Texel(texture,texture_coords).a);
    // lookup the colour in the palette by index
    ]],[[
    col.a = col.a*color.a*ta;
    return col;
}]],false,true)

shaders.stencilShader = love.graphics.newShader([[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      texture_coords.xy = mod(texture_coords.xy,1.0);
      if (Texel(texture, texture_coords).r == 0.0) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]])

return shaders