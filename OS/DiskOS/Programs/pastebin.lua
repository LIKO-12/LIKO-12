local term = require("terminal")
local lume = require("Libraries/lume")

local function printPBUsage()
  printUsage(
    "pastebin put <filename> [-c] [-u]",
    "Uploads a file into pastebin.com\n  "..
    "-c    Copy code to clipboard\n  "..
    "-u    Copy full URL to clipboard",
    "pastebin get <code> <filename>","Downloads a file from pastebin.com"
  )
end

local function printErr(str)
  color(8) print(str) color(7)
end

if not WEB then
  printErr( "Pastebin requires WEB peripheral" )
  printErr( "Edit /bios/bconf.lua and make sure that the WEB peripheral exists" )
  return
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
    elseif event == "keypressed" then
      if id == "escape" then
        return false, "Request Canceled"
      end
    end
  end
end

local args = { ... }
if #args < 2 then
  printPBUsage()
  return
end

local function getPaste(paste)
  color(9) print("Connecting to pastebin.com...") flip() color(7)
  local response, err = request("https://pastebin.com/raw/"..WEB.urlEncode(paste))
  
  if response then
    color(11) print( "Success." ) color(7) flip() sleep(0.01)
    
    return response
  else
    printErr("Failed: "..tostring(err))
  end
end

local command = args[1]
if command == "put" then
  -- Upload a file to pastebin.com
  -- Determine file to upload
  local file = args[2]
  local path = term.resolve(file)
  if not fs.exists(path) or fs.isDirectory(path) then
    printErr("No such file")
    return
  end
  
  -- Read in the file
  local name = getName(path:gsub("///","/"))
  local text = fs.read(path)
  
  -- POST the contents to pastebin
  color(9) print("Connecting to pastebin.com...") color(7) flip()
  local key = "e31065c6df5a451f3df3fdf5f4c2be61"
  local response, err = request("https://pastebin.com/api/api_post.php",{
    method = "POST",
    data = "api_option=paste&"..
           "api_dev_key="..key.."&"..
           (name:sub(-4,-1) == ".lua" and "api_paste_format=lua&" or "")..
           "api_paste_name="..WEB.urlEncode(name).."&"..
           "api_paste_code="..WEB.urlEncode(text)
  })
  
  if response then
    color(11) print("Success.") flip() sleep(0.01) color(7)
    
    local pasteCode = string.match(response, "[^/]+$")
    color(12) print("Uploaded as "..response) sleep(0.01)
    if lume.find(args,"-c") then print(pasteCode.." copied to clipboard") clipboard(pasteCode)
    elseif lume.find(args,"-u") then print("URL copied to clipboard") clipboard(response)
    end
    color(7)
    print('Run "',false) color(6) print('pastebin get '..pasteCode,false) color(7) print('" to download anywhere') sleep(0.01)
  else
    printErr("Failed: "..tostring(err))
  end
elseif command == "get" then
  -- Download a file from pastebin.com
  if #args < 3 then
    printPBUsage()
    return
  end
  
  --Determine file to download
  local pasteCode = args[2]
  local file = args[3]
  local path = term.resolve(file)
  if fs.exists( path ) then
    printErr("File already exists")
    return
  end
  
  -- Downloads the  pastebin
  local result = getPaste(pasteCode)
  if result then
    fs.write(path,result)
    
    color(12) print("Downloaded as "..file) sleep(0.01) color(7)
  else
    printErr("Failed")
  end
else
  printPBUsage()
  return
end