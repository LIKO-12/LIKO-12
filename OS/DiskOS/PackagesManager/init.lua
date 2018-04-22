--LIKO-12 DiskOS PackageManager

--CONFIG--
local defaultRepositories = {
  "https://raw.githubusercontent.com/RamiLego4Game/LK12-PKG-TEST/master/" --Test repository
}

--The path where the PackageManager is stored
local reqPath = string.gsub((... or ""),"/",".") --Used to require other files
local path = "C:/"..string.gsub(reqPath,"%.","/") --Used to refer to other files

local onMobile = isMobile() --Is LIKO-12 running on a mobile phone ?

--The package manager table
local pm = {}

pm.json = require(reqPath..".JSON") --The JSON library.
pm.http = require(reqPath..".Http") --The HTTP request library.

if not fs.exists("C:/Packages") then
  fs.newDirectory("C:/Packages")
end

if not fs.exists("C:/Packages/packages.json") then
  fs.write("C:/Packages/packages.json", "{}")
end

if not fs.exists(path.."/repositories.json") then
  fs.write(path.."/repositories.json", pm.json:encode_pretty(defaultRepositories))
end

if not fs.exists(path.."/repositories_packages.json") then
  fs.write(path.."/repositories_packages.json", "{}")
end

pm.repositories = pm.json:decode(fs.read(path.."/repositories.json")) --The repositories list
pm.repositories_packages = pm.json:decode(fs.read(path.."/repositories_packages.json")) --The repositories packages list cache

--Wait for the user to press y or n
function pm.yesNoInput(default)
  if onMobile then textinput(true) end
  
  for event, a,b,c,d,e,f in pullEvent do
    if event == "touchpressed" then
      textinput(true)
    elseif event == "keypressed" then
      if a == "return" then
        return default
      elseif a == "y" then
        return true
      elseif a == "n" then
        return false
      end
    end
  end
end

--Adds a new repository (requests user permissions)
function pm.addRepository(url)
  for id, purl in pairs(pm.repositories) do
    if purl == url then
      return 1, "Repository already added."
    end
  end
  
  color(9) print("Connecting to "..url.." ...") flip()
  local meta, err = http.get(url.."meta.json")
  if not meta then
    return 1, "Failed to connect: "..tostring(err)
  end
  
  meta = pm.json:decode(meta)
  
  color(6) print(string.format("\n- Author: %s\n- Name: %s\n- Description: %s\n", meta.Author or "-", meta.Name or "-", meta.Description or "-"))
  
  color(7) print("Are you sure you want to add this repository ? (Y/n)") flip()
  
  local userConfirmed = pm.yesNoInput(true)
  
  if not userConfirmed then return 1, "User rejected." end
  
  table.insert(pm.repositories,url)
  
  fs.write(path.."/repositories.json", pm.json:encode_pretty(pm.repositories))
  
  color(11) print("Repository added successfully.") flip()
  
  return 0 --Repo added successfully
end

function pm.updateRepositoriesPackagesCache()
  pm.repositories_packages = {} --Clear the packages cache
  color(9) print("Updating repositories packages list...\n") flip()
  
  color(6)
  
  for id, url in ipairs(pm.repositories) do
    print(string.format("(%d/%d) %s", id, #pm.repositories, url))
    local list, err = http.get(url.."packages.json")
    if list then
      pm.repositories_packages[url] = pm.json:decode(list)
    else
      pm.repositories_packages[url] = {}
      color(8) print("Failed: "..tostring(err)) color(6)
    end
  end
  
  fs.write(path.."/repositories_packages.json", pm.json:encode(pm.repositories_packages))
  
  local totalPackages = 0
  
  for id, list in pairs(pm.repositories_packages) do
    for id2, p in pairs(list) do
      totalPackages = totalPackages + #p
    end
  end
  
  color(11) print(string.format("\nDone, got %d packages",totalPackages))
  
  return 0
end

return pm