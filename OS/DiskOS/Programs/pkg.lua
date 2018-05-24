--LIKO-12 PackagesManager commandline utility

local command = ...
local args = {select(2,...)}

local pm = require("PackagesManager")

if not command or (command and command == "-?") then
  printUsage(
    "pkg addRepo <url>","Adds a repository",
    "pkg addRepo @clip","..from clipboard.",
    "pkg update","update repos packages list.",
    "pkg install <package>", "Installs a package",
    "pkg remove <package>", "Removes a package",
    "pkg search <quarry>", "Searches for a package"
  )
  return
end

if command == "addRepo" then
  local url = args[1]

  if not url then
    return 1, "Usage: pkg addRepo <url>"
  end

  if url == "@clip" then url = (clipboard() or "") end

  return pm.addRepository(url)
elseif command == "update" then
  return pm.updateRepositoriesPackagesCache()
elseif command == "install" then
  return pm.installPackage(args[1])
elseif command == "remove" then
  return pm.removePackage(args[1])
elseif command == "search" then
  return pm.search(args[1])
else
  return 1, string.format("Invalid command '%s', type 'pkg -?' for usage.",command)
end
