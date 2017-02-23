local destination = select(1,...)

local term = require("C://terminal")
destination = term.parsePath(destination)

if fs.exists(destination) and fs.isDirectory(destination) then color(9) print("Destination must not be a directory") return end

local eapi = _Editor

fs.write(destination,eapi:export())

print("Saved successfully")