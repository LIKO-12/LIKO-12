--DiskOS API Loader

local term = require("terminal")
local MainDrive = term.getMainDrive()

local Globals = (...) or {}

local apiloader = fs.load(MainDrive..":/System/api.lua")
setfenv(apiloader,Globals) apiloader()

return Globals