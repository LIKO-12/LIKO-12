--LIKO-12 DiskOS PackageManager

local term = require("terminal")
local MainDrive = term.getMainDrive()

--CONFIG--
local defaultRepositories = {
  "https://raw.githubusercontent.com/RamiLego4Game/LK12-PKG-TEST/master/" --Test repository
}

--The path where the PackageManager is stored
local reqPath = string.gsub((... or ""),"/",".") --Used to require other files
local path = MainDrive..":/"..string.gsub(reqPath,"%.","/") --Used to refer to other files

local onMobile = isMobile() --Is LIKO-12 running on a mobile phone ?

--The package manager table
local pm = {}

pm.json = require(reqPath..".JSON") --The JSON library.
pm.http = require(reqPath..".Http") --The HTTP request library.

if not fs.exists(MainDrive..":/Packages") then
  fs.newDirectory(MainDrive..":/Packages")
end

if not fs.exists(MainDrive..":/Packages/packages.json") then
  fs.write(MainDrive..":/Packages/packages.json", "{}")
end

for name in pairs(pm.json:decode(fs.read("C:/Packages/packages.json"))) do
  local chunk = fs.load("C:/Packages/" .. name .. "/init.lua")
  pcall(chunk, "C:/Packages/" .. name .. "/", "enable")
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

function pm.checkPackage(name)
  local flag = false
  local location, latest
  for reponame, packages in pairs(pm.repositories_packages) do
    for package, versions in pairs(packages) do
      if package == name then
        flag = true
        latest = versions[#versions]
        location = reponame
        break
      end
    end
  end
  return flag, fs.exists("C:/Packages/"..name), location, latest
end

function pm.installPackage(name, mode)
  mode = mode or "manual"
  local all, installed, reponame, latest = pm.checkPackage(name)
  if installed then
    return 1, "Package " .. name .. " is already installed."
  elseif not all then
    return 1, "Package " .. name .. " not found."
  else
    if mode == "manual" then
      color(9) print("Preparing to install " .. name .. ".")
    end
    local meta, err = http.get(reponame .. name .. "_" .. latest .. "/meta.json")
    if not meta then
      return 1, "Failed to get package: " .. tostring(err)
    end
    if mode == "manual" then
      color(7) print("Do you want to install this package ? (Y/n)") flip()
      answer = pm.yesNoInput(true)
      if not answer then return 1, "User rejected." end
    end
    for name_dep, version in pairs(pm.json:decode(meta)["Dependencies"]) do
      if name_dep == "liko12" then
        BIOS_VER = BIOS.getVersion()
        if not pm.checkVersion(BIOS_VER:sub(1,BIOS_VER:find("_")-1), version) then
          return 1, "This package requires a different version of LIKO-12"
        end
      elseif name_dep == "liko12.DiskOS" then
        if not pm.checkVersion("0.0.1", version) then
          return 1, "This package requires a different version of Disk OS"
        end
      else
        pm.installPackage(name_dep, "dependency")
      end
    end
    if mode == "manual" then
      color(9) print("Installed Dependencies")
    end
    local toc, err = http.get(reponame .. name .. "_" .. latest .. "/__toc.json")
    if not toc then
      return 1, "Failed to get package: " .. tostring(err)
    end
    fs.newDirectory("C:/Packages/" .. name)
    toc = pm.json:decode(toc)
    for _,file in pairs(toc) do
      if type(file) == "string" then
        local data, err = http.get(reponame .. name .. "_" .. latest .. "/" .. file)
        if not data then
          return 1, "Could not get: " .. file .. " " .. tostring(err)
        end
        fs.write("C:/Packages/" .. name .. "/" .. file, data)
        if mode == "manual" then
          color(9) print("Installed file: " .. file)
        end
      else
        dir = table.remove(file, 1)
        for _,subfile in pairs(file) do
          local data, err = http.get(reponame .. name .. "_" .. latest .. "/" .. dir .. "/" .. subfile)
          if not data then
            return 1, "Could not get: " .. subfile .. " " .. tostring(err)
          end
          fs.write("C:/Packages/" .. name .. "/" .. dir .. "/" .. subfile, data)
          if mode == "manual" then
            color(9) print("Installed file: " .. dir .. "/" .. subfile)
          end
        end
      end
    end
    local package_data = pm.json:decode(fs.read("C:/Packages/packages.json"))
    package_data[name] = {}
    package_data[name]["version"] = latest
    package_data[name]["mode"] = mode
    fs.write("C:/Packages/packages.json", pm.json:encode_pretty(package_data))
    if mode == "manual" then
      color(9) print("Finished installing " .. name)
    end
    local init = "C:/Packages/" .. name .. "/init.lua"
    local chunk, err = fs.load("C:/Packages/" .. name .. "/init.lua")
    if not chunk then return 1, "Unable to load init file." end
    term = require("terminal")
    term.executeFile(init, unpack({"C:/Packages/" .. name .. "/", "install"}))
    term.executeFile(init, unpack({"C:/Packages/" .. name .. "/", "enable"}))
  end
end

function pm.checkVersion(version, requirement)
  local _version = {}
  local _requirement = {}
  for i in string.gmatch(version, "%d+") do
    table.insert(_version, i)
  end
  for i in string.gmatch(requirement:sub(3, -1), "%d+") do
    table.insert(_requirement, i)
  end
  if requirement:sub(1, 2) == ">=" then
    for i = 1 , 3 do
      if tonumber(_version[i]) < tonumber(_requirement[i]) then
        return false
      end
    end
    return true
  end
end

function pm.removePackage(name, mode)
  mode = mode or "manual"
  local _, installed, _, _ = pm.checkPackage(name)
  if not installed then
    return 1, name .. " is not installed"
  end
  if mode == "manual" then
    color(9) print("Do you want to remove this package ? (Y/n)") flip()
    answer = pm.yesNoInput(true)
    if not answer then return 1, "User rejected." end
  end
  if mode == "manual" then
    color(9) print("Uninstalling Package")
  end
  local chunk = fs.load("C:/Packages/" .. name .. "/init.lua")
  pcall(chunk, "C:/Packages/" .. name .. "/", "disable", "uninstall")
  pcall(chunk, "C:/Packages/" .. name .. "/", "remove")
  if mode == "manual" then
    color(9) print("Unloaded Package")
  end
  fs.delete("C:/Packages/" .. name .. "/")
  if mode == "manual" then
    color(9) print("Deleted Package")
  end
  local data = pm.json:decode(fs.read("C:/Packages/packages.json"))
  data[name] = nil
  fs.write("C:/Packages/packages.json", pm.json:encode_pretty(data))
  if mode == "manual" then
    color(3) print("Uninstalled " .. name)
  end
end

function pm.search(quarry)
  local matches = {}
  for _, packages in pairs(pm.repositories_packages) do
    for package, _ in pairs(packages) do
      if string.find(package, quarry) then
        table.insert(matches, package)
      end
    end
  end
  color(9)
  for _, package in pairs(matches) do
    print(package)
  end
end

return pm
