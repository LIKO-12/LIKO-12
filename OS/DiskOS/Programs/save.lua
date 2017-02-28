local destination = select(1,...)

local term = require("C://terminal")
local eapi = require("C://Editors")
destination = term.parsePath(destination)

if fs.exists(destination) and fs.isDirectory(destination) then color(9) print("Destination must not be a directory") return end

fs.write(destination,eapi:export())

color(12) print("\nSaved successfully")