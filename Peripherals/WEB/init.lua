--WEB Peripheral
if (not love.thread) or (not jit) then error("WEB peripherals requires love.thread and luajit") end

local perpath = select(1,...) --The path to the web folder

local thread = love.thread.newThread(perpath.."webthread.lua")
local web_channel = love.thread.newChannel()