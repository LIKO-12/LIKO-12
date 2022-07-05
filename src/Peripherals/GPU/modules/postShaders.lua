--GPU: Post Shaders.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local events = require("Engine.events")

local MiscVars = GPUVars.Misc
local CursorVars = GPUVars.Cursor
local PShadersVars = GPUVars.PShaders

--==Varss Constants==--
local systemMessage = MiscVars.systemMessage

--==Local Variables==--

local _ActiveShaderID = 0
local _ActiveShaderName = "None"

--==GIF Control Keys==---
--(Used for also post shaders)
local _GIFStartKey = Config._GIFStartKey or "f8"
local _GIFEndKey = Config._GIFEndKey or "f9"
local _GIFPauseKey = Config._GIFPauseKey or "f7"

--==Hooks==--

--Handle post-shader switching
events.register("love:keypressed", function(key)
  if not love.keyboard.isDown("lshift","rshift") then return end
  if key ~= _GIFStartKey and key ~= _GIFEndKey and key ~= _GIFPauseKey then return end
  local shaderslist = love.filesystem.getDirectoryItems("/Shaders/")
  if key == _GIFEndKey then --Next Shader
    local nextShader = shaderslist[_ActiveShaderID + 1]
    if nextShader and love.filesystem.getInfo("/Shaders/"..nextShader,"file") then
      local ok, shader = pcall(love.graphics.newShader,"/Shaders/"..nextShader)
      if not ok then
        print("Failed to load shader",nextShader)
        shader = nil
      end
      
      _ActiveShaderID = _ActiveShaderID + 1
      _ActiveShaderName = nextShader
      PShadersVars.ActiveShader = shader
      PShadersVars.PostShaderTimer = nil
      
      if PShadersVars.ActiveShader then
        local warnings = PShadersVars.ActiveShader:getWarnings()
        if warnings ~= "vertex shader:\npixel shader:\n" then
          print("Shader Warnings:")
          print(warnings)
        end
        
        if PShadersVars.ActiveShader:hasUniform("time") then
          PShadersVars.PostShaderTimer = 0
        end
      else
        love.mouse.setVisible(not CursorVars.GrappedCursor)
      end
    else
      _ActiveShaderID = 0
      _ActiveShaderName = "None"
      PShadersVars.ActiveShader = nil
      PShadersVars.PostShaderTimer = nil
      love.mouse.setVisible(not CursorVars.GrappedCursor)
    end
  elseif key == _GIFStartKey then --Prev Shader
    local nextID = _ActiveShaderID - 1; if nextID < 0 then nextID = #shaderslist end
    local nextShader = shaderslist[nextID]
    if nextShader and love.filesystem.getInfo("/Shaders/"..nextShader,"file") then
      local ok, shader = pcall(love.graphics.newShader,"/Shaders/"..nextShader)
      if not ok then
        print("Failed to load shader",nextShader)
        print(shader)
        shader = nil
      end
      
      _ActiveShaderID = nextID
      _ActiveShaderName = nextShader
      PShadersVars.ActiveShader = shader
      PShadersVars.PostShaderTimer = nil
      
      if PShadersVars.ActiveShader then
        local warnings = PShadersVars.ActiveShader:getWarnings()
        if warnings ~= "vertex shader:\npixel shader:\n" then
          print("Shader Warnings:")
          print(warnings)
        end
        
        if PShadersVars.ActiveShader:hasUniform("time") then
          PShadersVars.PostShaderTimer = 0
        end
      else
        love.mouse.setVisible(not CursorVars.GrappedCursor)
      end
    else
      _ActiveShaderID = 0
      _ActiveShaderName = "None"
      PShadersVars.ActiveShader = nil
      PShadersVars.PostShaderTimer = nil
      love.mouse.setVisible(not CursorVars.GrappedCursor)
    end
  elseif key == _GIFPauseKey then --None Shader
    _ActiveShaderID = 0
    _ActiveShaderName = "None"
    PShadersVars.ActiveShader = nil
    PShadersVars.PostShaderTimer = nil
    love.mouse.setVisible(not CursorVars.GrappedCursor)
  end
  
  systemMessage("Shader: ".._ActiveShaderName,2,false,false,true)
end)

--Post-Shader Time value
events.register("love:update",function(dt)
  if PShadersVars.PostShaderTimer then
    PShadersVars.PostShaderTimer = (PShadersVars.PostShaderTimer + dt)%10
  end
end)