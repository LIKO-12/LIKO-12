--GPU: Miscellaneous Things.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local events = require("Engine.events")

local MiscVars = GPUVars.Misc
local RenderVars = GPUVars.Render

--==System Message==--

MiscVars.LastMSG = "" --Last system message.
MiscVars.LastMSGTColor = 4 --Last system message text color.
MiscVars.LastMSGColor = 9 --Last system message color.
MiscVars.LastMSGGif = false --Show Last system message in the gif recording ?
MiscVars.MSGTimer = 0 --The message timer.

local function systemMessage(msg,time,tcol,col,hideInGif)
  if not msg then MiscVars.MSGTimer = 0 end --Clear last message
  if type(msg) ~= "string" then return error("Message must be a string, provided: "..type(msg)) end
  
  if time and type(time) ~= "number" then return error("Time must be a number or a nil, provided: "..type(time)) end
  if tcol and type(tcol) ~= "number" then return error("Text color must be a number or a nil, provided: "..type(tcol)) end
  if col and type(col) ~= "number" then return error("Body Color must be a number or a nil, provided: "..type(col)) end
  time, tcol, col = time or 1, math.floor(tcol or 4), math.floor(col or 9)
  if time < 0 then return error("Time can't be negative") end
  if tcol < 0 or tcol > 15 then return error("Text Color ID out of range ("..tcol..") Must be [0,15]") end
  if col < 0 or col > 15 then return error("Body Color ID out of range ("..col..") Must be [0,15]") end
  MiscVars.LastMSG = msg
  MiscVars.LastMSGTColor = tcol
  MiscVars.LastMSGColor = col
  MiscVars.LastMSGGif = not hideInGif
  MiscVars.MSGTimer = time
  
  return true
end

function GPU._systemMessage(msg,time,tcol,col,hideInGif)
  local ok, err = pcall(systemMessage,msg,time,tcol,col,hideInGif)
  if not ok then return error(err) end
end

events.register("love:update",function(dt)
  if MiscVars.MSGTimer > 0 then
    MiscVars.MSGTimer = MiscVars.MSGTimer - dt
    RenderVars.ShouldDraw = true
  end
end)

MiscVars.systemMessage = systemMessage