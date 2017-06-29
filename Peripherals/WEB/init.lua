local perpath = select(1,...) --The path to the web folder

local events = require("Engine.events")
local json = require("Engine.json")

local thread = love.thread.newThread(perpath.."webthread.lua")
local to_channel = love.thread.getChannel("To_WebThread")
local from_channel = love.thread.getChannel("From_WebThread")

local to_counter = 0
local from_counter = 0

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
    
    args = json:encode(args)
    
    to_channel:push({url,args})
    to_counter = to_counter + 1
    
    return true, to_counter --Return the request ID
  end
  
  events:register("love:update",function(dt)
    local result = from_channel:pop()
    if result then
      from_counter = from_counter +1
      local data = json:decode(result)
      CPUKit.triggerEvent("webrequest",from_counter,unpack(data))
    end
  end)
  
  return WEB, devkit, indirect
end