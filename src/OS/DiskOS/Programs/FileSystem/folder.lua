--Opens the host file explorer in the current active folder

if (...) == "-?" then
  printUsage(
    "folder","Opens the host file explorer in the current active folder",
    "folder --path","Shows the real path of the current active folder"
  )
  return
end

local term = require("terminal")

if isMobile() or (...) == "--path" then
  color(9) print("Current folder location: ")
  color(6) print(getSaveDirectory().."/Drives/"..term.getdrive()..term.getdirectory())
else
  openAppData("/Drives/"..term.getdrive()..term.getdirectory())
end