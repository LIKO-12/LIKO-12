--This program is based on ComputerCraft one: https://github.com/dan200/ComputerCraft/blob/master/src/main/resources/assets/computercraft/lua/rom/programs/http/pastebin.lua

local term = require("C://terminal")

local function printUsage()
  color(9) print("Usages:") color(7)
  print("pastebin put <filename>")
  print("pastebin get <code> <filename>")
end

local function printError(str)
  color(8) print(str) color(7)
end

local function getName(str)
  local path, name, ext = string.match(str, "(.-)([^\\/]-%.?([^%.\\/]*))$")
  return name
end

local function request(url, args)
  local ticket = WEB.send(url,args)
  for event, id, url, data, errnum, errmsg, errline in pullEvent do
    if event == "webrequest" then
      if id == ticket then
        if data then
          data.code = tonumber(data.code)
          if (data.code < 200 or data.code >= 300) and data.body:sub(1,21) ~= "https://pastebin.com/" then
            cprint("Body: "..tostring(data.body))
            return false, "HTTP Error: "..data.code
          end
          if data.body:sub(1,15) == "Bad API request" then
            return false, "API Error: "..data.body
          end
          return data.body
        else
          return false, errmsg
        end
      end
    end
  end
end

local tArgs = { ... }
if #tArgs < 2 then
  printUsage()
  return
end

if not WEB then
  printError( "Pastebin requires WEB peripheral" )
  printError( "Edit /bios/bconf.lua and make sure that the WEB peripheral exists" )
  return
end

local function get(paste)
  color(9) print("Connecting to pastebin.com...") flip() color(7)
  local response, err = request("https://pastebin.com/raw/"..WEB.urlEncode(paste))
  
  if response then
    color(11) print( "Success." ) color(7) flip() sleep(0.01)
    
    return response
  else
    printError("Failed: "..tostring(err))
  end
end

local sCommand = tArgs[1]
if sCommand == "put" then
  -- Upload a file to pastebin.com
  -- Determine file to upload
  local sFile = tArgs[2]
  local sPath = term.resolve(sFile)
  if not fs.exists(sPath) or fs.isDirectory(sPath) then
    printError("No such file")
    return
  end
  
  -- Read in the file
  local sName = getName(sPath:gsub("///","/"))
  local sText = fs.read(sPath)
  
  -- POST the contents to pastebin
  color(9) print("Connecting to pastebin.com...") color(7) flip()
  local key = "e31065c6df5a451f3df3fdf5f4c2be61"
  local response, err = request("https://pastebin.com/api/api_post.php",{
    method = "POST",
    data = "api_option=paste&"..
           "api_dev_key="..key.."&"..
           "api_paste_format=lua&"..
           "api_paste_name="..WEB.urlEncode(sName).."&"..
           "api_paste_code="..WEB.urlEncode(sText)
  })
  
  if response then
    color(11) print("Success.") flip() sleep(0.01) color(7)
    
    local sCode = string.match(response, "[^/]+$")
    color(12) print("Uploaded as "..response) sleep(0.01) color(7)
    print('Run "',false) color(6) print('pastebin get '..sCode,false) color(7) print('" to download anywhere') sleep(0.01)
  else
    printError("Failed: "..tostring(err))
  end
elseif sCommand == "get" then
  -- Download a file from pastebin.com
  if #tArgs < 3 then
    printUsage()
    return
  end
  
  --Determine file to download
  local sCode = tArgs[2]
  local sFile = tArgs[3]
  local sPath = term.resolve(sFile)
  if fs.exists( sPath ) then
    printError("File already exists")
    return
  end
  
  -- GET the contents from pastebin
  local res = get(sCode)
  if res then
    fs.write(sPath,res)
    
    color(12) print("Downloaded as "..sFile) sleep(0.01) color(7)
  end
else
  printUsage()
  return
end