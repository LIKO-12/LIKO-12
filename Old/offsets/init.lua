local OS = love.system.getOS()
if OS == "Android" then require("offsets.android") else require("offsets.desktop") end