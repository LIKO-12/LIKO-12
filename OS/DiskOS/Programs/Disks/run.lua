--This file loads a lk12 disk and executes it
if select(1,...) == "-?" then
  printUsage(
    "run [...]","Runs the current loaded game with any provided arguments"
  )
  return
end

local Runtime = require("Runtime")

local glob, co, chunk = Runtime.loadGame()

if not glob then return 1, co end

local ok, err = Runtime.runGame(glob, co,...)

if not ok then return 1, err end

return 0