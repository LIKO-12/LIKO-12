--GPU: Miscellaneous Things.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local events = require("Engine.events")

local MiscKit = GPUKit.Misc
local RenderKit = GPUKit.Render

--==System Message==--

MiscKit.LastMSG = "" --Last system message.
MiscKit.LastMSGTColor = 4 --Last system message text color.
MiscKit.LastMSGColor = 9 --Last system message color.
MiscKit.LastMSGGif = false --Show Last system message in the gif recording ?
MiscKit.MSGTimer = 0 --The message timer.

local function systemMessage(msg,time,tcol,col,hideInGif)
  if not msg then MiscKit.MSGTimer = 0 end --Clear last message
  if type(msg) ~= "string" then return false, "Message must be a string, provided: "..type(msg) end
  
  if time and type(time) ~= "number" then return false, "Time must be a number or a nil, provided: "..type(time) end
  if tcol and type(tcol) ~= "number" then return false, "Text color must be a number or a nil, provided: "..type(tcol) end
  if col and type(col) ~= "number" then return false, "Body Color must be a number or a nil, provided: "..type(col) end
  time, tcol, col = time or 1, math.floor(tcol or 4), math.floor(col or 9)
  if time <= 0 then return false, "Time must be bigger than 0" end
  if tcol < 0 or tcol > 15 then return false, "Text Color ID out of range ("..tcol..") Must be [0,15]" end
  if col < 0 or col > 15 then return false, "Body Color ID out of range ("..col..") Must be [0,15]" end
  MiscKit.LastMSG = msg
  MiscKit.LastMSGTColor = tcol
  MiscKit.LastMSGColor = col
  MiscKit.LastMSGGif = not hideInGif
  MiscKit.MSGTimer = time
  
  return true
end

function GPU._systemMessage(msg,time,tcol,col,hideInGif)
  return systemMessage(msg,time,tcol,col,hideInGif)
end

events.register("love:update",function(dt)
  if MiscKit.MSGTimer > 0 then
    MiscKit.MSGTimer = MiscKit.MSGTimer - dt
    RenderKit.ShouldDraw = true
  end
end)

GPUKit.systemMessage = systemMessage