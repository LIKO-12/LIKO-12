--Opens the host file explorer in the current active folder

if select(1,...) == "-?" then
  printUsage(
    "folder","Opens the host file explorer in the current active folder"
  )
  return
end

local term = require("terminal")
if isMobile() then
  color(9) print("Current folder location: ")
  color(6) print(getSaveDirectory().."/drives/"..term.getdrive()..term.getdirectory())
else
  openAppData("/drives/"..term.getdrive()..term.getdirectory())
end