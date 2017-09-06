if select(1,...) == "-?" then
  printUsage("reload","Reload system files")
  return
end

local term = require("terminal")
term.reload()

color(11)
print("Reloaded Successfully")