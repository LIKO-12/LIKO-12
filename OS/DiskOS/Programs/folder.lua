--Opens the host file explorer in the current active folder

if select(1,...) == "-?" then
  printUsage(
    "folder","Opens the host file explorer in the current active folder"
  )
  return
end

local term = require("C://terminal")
openAppData("/drives/"..term.getdrive()..term.getdirectory())