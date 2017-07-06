local perpath = select(1,...) --The path to the web folder

local bit = require("bit")

local events = require("Engine.events")
local json = require("Engine.JSON")

local thread = love.thread.newThread(perpath.."webthread.lua")
local to_channel = love.thread.newChannel()
local from_channel = love.thread.newChannel()

local to_counter = 0
local from_counter = 0

thread:start(to_channel, from_channel)

local function clearFuncsFromTable(t)
  for k,v in pairs(t) do
    if type(v) == "function" then
      t[k] = nil
    elseif type(v) == "table" then
      clearFuncsFromTable(v)
    end
  end
end

return function(config) --A function that creates a new WEB peripheral.
  if not thread:isRunning() then error("Failed to load luajit-request: "..tostring(thread:getError())) end
  
  local timeout = config.timeout or 5
  
  local CPUKit = config.CPUKit
  if not CPUKit then error("WEB Peripheral can't work without the CPUKit passed") end
  
  local indirect = {} --List of functions that requires custom coroutine.resume
  
  local devkit = {}
  
  local WEB = {}
  
  function WEB.send(url,args)
    if type(url) ~= "string" then return false, "URL must be a string, provided: "..type(url) end
    local args = args or {}
    if type(args) ~= "table" then return false, "Args Must be a table or nil, provided: "..type(args) end
    
    clearFuncsFromTable(args) --Since JSON can't encode functions !
    args.timeout = timeout
    
    args = json:encode(args)
    
    to_channel:push({url,args})
    to_counter = to_counter + 1
    
    return true, to_counter --Return the request ID
  end
  
  function WEB.urlEncode(str)
    if type(str) ~= "string" then return false, "STR must be a string, provided: "..type(str) end
    str = str:gsub("\n", "\r\n")
    str = str:gsub("\r\r\n", "\r\n")
    tr = str:gsub("([^A-Za-z0-9 %-%_%.])", function(c)
      local n = string.byte(c)
      if n < 128 then
        -- ASCII
        return string.format("%%%02X", n)
      else
        -- Non-ASCII (encode as UTF-8)
        return string.format("%%%02X", 192 + bit.band( bit.arshift(n,6), 31 )) .. 
               string.format("%%%02X", 128 + bit.band( n, 63 ))
      end
    end)
    
    str = str:gsub("%+", "%%2b")
    str = str:gsub(" ", "+")
    
    return true,str
  end
  
  events:register("love:update",function(dt)
    local result = from_channel:pop()
    if result then
      from_counter = from_counter +1
      local data = json:decode(result)
      CPUKit.triggerEvent("webrequest",from_counter,unpack(data))
    end
  end)

  events:register("love:reboot",function()
    to_channel:clear()
    to_channel:push("shutdown")
  end)

  events:register("love:quit",function()
    to_channel:clear()
    to_channel:push("shutdown")
    thread:wait()
  end)
  
  return WEB, devkit, indirect
end