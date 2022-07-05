--WEB Peripheral
if (not love.thread) or (not jit) then error("WEB peripherals requires love.thread and luajit") end

local perpath = (...) --The path to the web folder
local events = require("Engine.events")

--Check if we have libcurl and/or luasec
local has_libcurl = pcall(require,"Engine.luajit-request")
local has_luasec = pcall(require,"ssl")

--Constants
local auth_types = { none=true, basic=true, digest=true, negotiate=true }
local requestFields = {"method","headers","data","cookies","allow_redirects","auth_type","username","password"}
local luasocket_modules = {
  "socket.http", "ltn12", "mime", "socket.smtp", "socket", "socket.url"
}
for k,v in ipairs(luasocket_modules) do luasocket_modules[v] = require(v) end

--Value, expected Type, Variable Name
local function Verify(value,name,etype,allowNil)
  if type(value) ~= etype and not (allowNil and type(value) == "nil") then
    if allowNil then
      error(name.." should be a "..etype.." or a nil, provided: "..type(value),3)
    else
      error(name.." should be a "..etype..", provided: "..type(value),3)
    end
  end
  
  if etype == "number" then
    return math.floor(value)
  end
end

return function(config)
  
  local CPUKit = config.CPUKit
  
  --==Thread Initialization==--
  
  local thread = love.thread.newThread(perpath.."webthread.lua")
  local web_channel = love.thread.newChannel()
  local idle_channel = love.thread.newChannel()
  
  thread:start(web_channel,idle_channel,perpath)
  
  --==Thread State Variables==--
  
  local requestsStack = {}
  local nextRequestID = 1
  local currentRequestID = false
  
  --==WEB API==--
  
  local WEB, yWEB = {}, {}
  
  function WEB.request(url,request,lib)
    request = request or {}
    
    Verify(url,"URL","string")
    Verify(request,"Request","table",true)
    Verify(request.method,"Request.method","string",true)
    Verify(request.headers,"Request.headers","table",true)
    Verify(request.data,"Request.data","string",true)
    Verify(request.cookies,"Request.cookies","string",true)
    Verify(request.allow_redirects,"Request.allow_redirects","boolean",true)
    Verify(request.auth_type,"Request.auth_type","string",true)
    Verify(request.username,"Request.username","string",true)
    Verify(request.password,"Request.password","string",true)
    Verify(lib,"Library","string",true)
    
    if lib then
      if lib == "libcurl" then
        if not has_libcurl then return error("LibCurl is not available.") end
      elseif lib == "luasec" then
        if not has_luasec then return error("LuaSec is not available.") end
      elseif lib ~= "luasocket" then
        return error("Invalid library: "..lib)
      end
    end
    
    request.method = request.method or (request.data and "POST" or "GET")
    if request.headers then
      for k,v in pairs(request.headers) do
        request.headers[k] = tostring(v)
      end
    end
    request.auth_type = request.auth_type or "none"
    if not auth_types[request.auth_type] then return error("Invalid Request.auth_type: "..request.auth_type) end
    if request.auth_type == "digest" or request.auth_type == "negotiate" then
      if has_libcurl and ((not lib) or lib == "libcurl") then
        lib = "libcurl"
      elseif lib then
        return error("Request.auth_type ("..request.auth_type..") is not supported by luasec nor luasocket, use libcurl instead if available.")
      else
        return error("Request.auth_type ("..request.auth_type..") is not supported by luasec nor luasocket, and libcurl is not available.")
      end
    end
    
    local nrequest = {}
    for k,v in pairs(requestFields) do
      nrequest[v] = request[v]
    end
    
    if not nrequest.headers then nrequest.headers = {} end
    nrequest.headers["user-agent"] = nrequest.headers["user-agent"] or "LIKO-12"
    nrequest.headers["content-type"] = nrequest.headers["content-type"] or "application/x-www-form-urlencoded"
    
    nrequest.url = url
    nrequest.lib = lib
    
    requestsStack[nextRequestID] = nrequest
    if not currentRequestID then
      --Put the request instantly into the thread.
      nrequest.lib = nil
      idle_channel:push(lib)
      web_channel:push(nrequest)
      currentRequestID = nextRequestID
    end
    nextRequestID = nextRequestID + 1
    
    return nextRequestID-1
  end
  
  function WEB.clearRStack()
    if not currentRequestID or currentRequestID == nextRequestID-1 then return end
    for i=currentRequestID+1,nextRequestID-1 do
      requestsStack[i] = nil
      nextRequestID = nextRequestID -1
    end
  end
  
  if not CPUKit then
    print("WEB.request and WEB.clearRStack has been removed because CPUKit is not passed to the WEB peripheral")
    WEB.request, WEB.clearRStack = nil, nil
  end
  
  function WEB.luasocket(submodule)
    Verify(submodule,"Submodule","string")
    submodule = string.lower(submodule)
    if not luasocket_modules[submodule] then return error("Invalid submodule: "..submodule) end
    return luasocket_modules[submodule]
  end
  
  function WEB.hasLuaSec()
    return has_luasec and true or false
  end
  
  function WEB.hasLibCurl()
    return has_libcurl and true or false
  end
  
  function WEB.hasHTTPS()
    return (has_libcurl or has_luasec) and true or false
  end
  
  function WEB.luasec(submodule)
    if not has_luasec then return error("LuaSec is not available on this device.") end
    
    Verify(submodule,"Submodule","string")
    submodule = string.lower(submodule)
    if submodule ~= "ssl" and submodule ~= "https" then return error("Invalid submodule: "..submodule) end
    
    if submodule == "https" then
      return require(perpath.."LuaSec/https")
    end
    
    return require(submodule)
  end
  
  --==Hooks==--
  
  events.register("love:update",function()
    if not currentRequestID then return end
    local progress = web_channel:pop()
    if progress then
      local triggerData = web_channel:demand()
      local triggerName = "HTTP_"..string.upper(progress:sub(1,1))..progress:sub(2,-1)
      local triggerID = currentRequestID
      
      if progress == "respond" or progress == "failed" then
        currentRequestID = currentRequestID + 1
        if nextRequestID == currentRequestID then
          currentRequestID = false
        else
          local request = requestsStack[currentRequestID]
          local lib = request.lib
          request.lib = nil
          
          idle_channel:push(lib)
          web_channel:push(request)
        end
      end
      
      CPUKit.triggerEvent(triggerName,triggerID,triggerData)
    end
  end)
  
  events.register("love:reboot",function()
    idle_channel:push("shutdown")
  end)

  events.register("love:quit",function()
    idle_channel:push("shutdown")
    thread:wait()
  end)
  
  return WEB, yWEB
  
end