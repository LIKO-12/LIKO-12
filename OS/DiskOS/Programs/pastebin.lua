local term = require("terminal")
local lume = require("Libraries/lume")

local function printPBUsage()
  printUsage(
    "pastebin put <filename> [-c] [-u]",
    "Uploads a file into pastebin.com\n  "..
    "-c    Copy code to clipboard\n  "..
    "-u    Copy full URL to clipboard",
    "pastebin get <code> <filename>","Downloads a file from pastebin.com",
    "pastebin run <code>","Runs a Lua file from pastebin.com"
  )
end

local function printErr(str)
  color(8) print(str) color(7)
end

if not WEB then
  return 1, "Pastebin requires WEB peripheral\nEdit /bios/bconf.lua and make sure that the WEB peripheral exists"
end

local function getName(str)
  local path, name, ext = string.match(str, "(.-)([^\\/]-%.?([^%.\\/]*))$")
  return name
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
    return 1, "Failed: "..tostring(err)
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
  local size = fs.getSize(path)
  if size > 512*1024 then color(8) print("File too large to upload,\nuse 'save <game> -c' when saving.") color(7) end
  local text = fs.read(path)
  
  -- POST the contents to pastebin
  color(9) print("Connecting to pastebin.com...") color(7) flip()
  local key = "e31065c6df5a451f3df3fdf5f4c2be61"
  local response, err = request("https://pastebin.com/api/api_post.php", 
    "api_option=paste&"..
    "api_dev_key="..key.."&"..
    (name:sub(-4,-1) == ".lua" and "api_paste_format=lua&" or "")..
    "api_paste_name="..WEB.urlEncode(name).."&"..
    "api_paste_code="..WEB.urlEncode(text)
  )
  
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
    return 1, "Failed: "..tostring(err)
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
    return 1, "File already exists"
  end
  
  -- Downloads the  pastebin
  local result = getPaste(pasteCode)
  if result then
    fs.write(path,result)
    
    color(12) print("Downloaded as "..file) sleep(0.01) color(7)
  else
    return 1, "Failed"
  end
elseif command == "run" then
  -- Run a file from pastebin.com
  if #args < 2 then
    printPBUsage()
    return
  end
  
  --Determine file to download
  local pasteCode = args[2]
  
  -- Downloads the  pastebin
  local result = getPaste(pasteCode)
  if result then
    fs.write("C:/.temp/"..pasteCode..".lua",result)
    term.executeFile("C:/.temp/"..pasteCode..".lua")
  else
    return 1, "Failed"
  end
else
  printPBUsage()
  return
end