if (...) and (...) == "-?" then
  printUsage(
    "resave_osdisks", "Loads and saves the Games and Demos on the C drive, used by the developer, not useful for users."
  )
  return
end

local term = require("terminal")

local function update(dir)
  for id, name in ipairs(fs.getDirectoryItems(dir)) do
    color(6) print(name)
    term.execute("load",dir..name) flip()
    term.execute("save") flip()
  end
end

update("C:/Demos/")
update("C:/Games/")

color(11) print("Updated disks successfully.")