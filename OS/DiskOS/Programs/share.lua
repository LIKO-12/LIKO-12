local function printUse()
  printUsage(
    "share list", "lists types of sharables",
    "share put <type> <filename>", "sends a file as that type",
    "share get <filename>", "Downloads the file with that name"
  )
end

local types = {}
types["lua"] = " "
types["xshell"] = " "
types["other"] = " "

local function getConfig(paste, pos)
  newPos = string.find(paste, "\n", pos)
  data = string.sub(paste, pos, newPos-2)
  return newPos, data
end

local function request(url,postdata,headers,method)

  local body, data, data2 = http.request(url,postdata,headers,method)

  if body then
    if data.body:sub(1,15) == "Bad API request" then
      return false, "API Error: "..data.body
    end
  elseif data2 then
    if data2.body and data2.body:sub(1,21) == "https://pastebin.com/" then
      return data2.body
    end
  end

  return body, data
end

local args = {...}
if #args < 1 or args[1] == "-?" then
  printUse()
  return
end

local term = require("terminal")

local command = args[1]

if command == "list" then
  for k, _ in pairs(types) do
    print(k)
  end
  print("")
elseif command == "put" then
  if not WEB then
    return 1, "Pastebin requires WEB peripheral\nEdit /bios/bconf.lua and make sure that the WEB peripheral exists"
  end

  local config = ConfigUtils.get("ShareSystem")
  config.code = config.code or "NoCode"

  local type = args[2]
  local filename = args[3]
  local path = term.resolve(filename)
  if not fs.exists(path) or fs.isDirectory(path) then
    return 1, "File " ..path .. " not found"
  end
  local size = fs.getSize(path)
  if size > 512*1024 then return 1, "File too large to upload" end
  local text = (config.code).."\n"..type.."\n"..path.."\n"..fs.read(path)
  local name = type.." "..fs.getName(path)
  local key = "e31065c6df5a451f3df3fdf5f4c2be61"
  local response, err = request("https://pastebin.com/api/api_post.php",
    "api_option=paste&"..
    "api_dev_key="..key.."&"..
    "api_paste_name="..WEB.urlEncode(name).."&"..
    "api_paste_code="..WEB.urlEncode(text)
  )

  if response then
    color(11) print("Success") color(7)
    local pasteCode = string.match(response, "[^/]+$")
    config.code = pasteCode
  else
    return 1, "Failed: "..tostring(err)
  end

  ConfigUtils.saveConfig()
elseif command == "get" then
  local config = ConfigUtils.get("ShareSystem")
  config.code = config.code or "NoCode"

  if config.code == "NoCode" then
    return 1, "There is not a code in the config system"
  end

  local pos, type, path, response, err
  local nextCode = config.code

  local filename = term.resolve(args[2])
  repeat
    if nextCode == "NoCode" then
      return 1, "File "..filename.." not found"
    end
    currentCode = nextCode
    response, err = request("https://pastebin.com/raw/"..WEB.urlEncode(currentCode))
    if response then
      pos, nextCode = getConfig(response, 0)
      pos, type = getConfig(response, pos+1)
      pos, pastePath = getConfig(response, pos+1)
    else
      return 1, "Failed: "..tostring(err)
    end
  until (pastePath == filename)
  data = string.sub(response, pos+1)
  fs.write(filename, data)
end
