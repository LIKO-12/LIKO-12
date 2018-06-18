--DiskOS API Loader

local Globals = (...) or {}

local apiloader = fs.load("System/api.lua")
setfenv(apiloader,Globals) apiloader()

return Globals