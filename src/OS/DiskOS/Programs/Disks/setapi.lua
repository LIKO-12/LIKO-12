local eapi = require("Editors")

local args = {...}

if #args < 1 or args[1] == "-?" then
  color(9) print("Current disk API: ",false)
  color(10) print("v"..eapi.apiVersion)
  color(9) print("Latest API: ",false)
  color(10) print("v".._APIVer)
  
  print("")
  
  printUsage(
    "setapi","Show this information.",
    "setapi <apiVer>","Sets the currently loaded disk API version.",
    "help API_<apiVer>","Show the list of changes since the previous API version."
  )
  
  return
end

local uV = tonumber(args[1])
if not uV then return 1, "Invalid API version: "..uV end
if uV ~= math.floor(uV) or uV < 1 then return 1, "Invalid API version: "..uV end
if uV > _APIVer then return 1, "Current LIKO-12 version doesn't support API v"..uV end

eapi.apiVersion = uV
color(11) print("API has been successfully set to v"..uV)
color(6) print("Type 'help API_"..uV.."' for the API changes list.")