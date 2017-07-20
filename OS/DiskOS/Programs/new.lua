if select(1,...) == "-?" then
  printUsage(
    "new","Clears editors data"
  )
  return
end

local eapi = require("Editors")
eapi.filePath = nil
eapi:clearData()
color(11) print("Cleared editors data successfully")