--Lists the folders and files at the current directory.
--An alies of ls.lua

if select(1,...) == "-?" then
  printUsage(
    "dir","Lists the files and folders in the current directory",
    "dir <dir>","Lists the files and folders in a specific directory"
  )
  return
end

local term = require("terminal") --Require the terminal api.
return term.execute("ls",...)