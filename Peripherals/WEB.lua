local events = require("Engine.events")
local request = require("Engine.luajit-request")

events:register("love:quit", function()
  request.close() --Closed the CURL Request
end)

return function(config) --A function that creates a new WEB peripheral.
  local indirect = {} --List of functions that requires custom coroutine.resume
  
  local devkit = {}
  
  local WEB = {}
  
  function WEB.send(url,args)
    if type(url) ~= "string" then return false, "URL must be a string, provided: "..type(url) end
    if args and type(args) ~= "table" then return false, "Args Must be a table or nil, provided: "..type(args) end
    return pcall(request.send,url,args)
  end
  
  return WEB, devkit, indirect
end