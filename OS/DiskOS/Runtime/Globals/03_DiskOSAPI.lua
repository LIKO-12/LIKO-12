--DiskOS API Loader

local Globals = (...) or {}

local apiloader = fs.load("C:/System/api.lua")
setfenv(apiloader,Globals) apiloader()

return Globals