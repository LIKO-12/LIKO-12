--A non-interactive network retriever
local term = require("terminal")
local args = {...} --Get the arguments passed to this program

local function printErr(str)
  color(8) print(str) color(7)
end

if #args < 1 or args[1] == "-?" then
  printUsage(
    "wget <address>", "Download the document at <address>",
    "wget <address> <filename>", "Download the document at <address> and save it as <filename>"
  )
  return
end

if not WEB then
  return 1, "wget requires WEB peripheral\nEdit /bios/bconf.lua and make sure that the WEB peripheral exists"
end

local address = args[1]
local filename = args[2]

if address ~= nil then
  print("Downloading " .. address .. "...")
  local body, data, data2 = http.request(address)

  if data then
    if tonumber(data.code) ~= 200 then
      return 1, "Request error, HTTP Error code: " .. data.code
    else
      if not filename then
        local tokens = split(address, '/')
        filename = tokens[#tokens]
      end
      if fs.exists(filename) then
        return 1, "File called " .. filename .. " already exists!"
      else
        print("Saving to '" .. filename .. "'")
        fs.write(filename, body)
        print("File saved!")
      end

      return 0
    end
  else
    return 1, "The request did not return any data"
  end
end
