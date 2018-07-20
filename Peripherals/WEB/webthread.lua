--WEB Peripheral Thread

print("------------------------------")

--Thread communication channels
local web_channel, idle_channel, peripheral_path = ...

--Check if we have libcurl and/or luasec
local has_libcurl = pcall(require,"Engine.luajit-request")
local has_luasec = pcall(require,"ssl")
print(has_libcurl and "- libcurl is available" or "- libcurl is not available")
print(has_luasec and "- luasec is available" or "- luasec is not available")
print((has_libcurl or has_luasec) and (has_luasec and "- using luasec for https" or "- using libcurl for https") or "- https is not available")

print("------------------------------")

--Load the libraries

--Luajit-Request
local lj_request
if has_libcurl then
  lj_request = require("Engine.luajit-request")
end

local function lj_body_stream(chunk)
  if not chunk then return end
  
  web_channel:push("body")
  web_channel:push(chunk)
end

--LuaSec
local ls_https
if has_luasec then
  ls_https = require(peripheral_path.."https")
  ls_https.USERAGENT = "LIKO-12"
end

--LuaSocket
local ls_http = require("socket.http")
local ls_ltn12 = require("ltn12")
local ls_url = require("socket.url")

ls_http.USERAGENT = "LIKO-12"

local ls_body --Set later when requesting to an empty table
local function ls_sink(chunk)
  if not chunk then return end
  
  web_channel:push("body")
  web_channel:push(chunk)
  
  ls_body[#ls_body + 1] = chunk
  
  return 1
end

while true do
  local specifiedLibrary = idle_channel:demand()
  if type(specifiedLibrary) == "string" and specifiedLibrary == "shutdown" then break end
  
  local request = web_channel:demand()
  
  --Use LuaJIT-Request if LuaSec is not available
  if has_libcurl and ((not has_luasec) or (specifiedLibrary and specifiedLibrary == "libcurl")) then
    
    local url = request.url
    request.url = nil
    
    request.timeout = 1
    request.body_stream_callback = lj_body_stream
    
    local respond, _, message = lj_request.send(url,request)
    
    if respond then
      web_channel:push("respond")
      web_channel:push(respond)
    else
      web_channel:push("failed")
      web_channel:push(tostring(message))
    end
    
  else --Use luaSec or luaSocket
    local http = ls_https or ls_http
    
    if specifiedLibrary and specifiedLibrary == "luasocket" then
      http = ls_http
    end
    
    ls_body = {} --Reset the receive body.
    
    if request.auth_type and request.auth_type == "basic" then
      local parsedURL = ls_url.parse(request.url)
      parsedURL.user = request.username or parsedURL.user
      parsedURL.password = request.password or parsedURL.password
      request.url = ls_url.build(parsedURL)
    end
    
    local http_req = {
      url = request.url,
      sink = ls_sink,
      method = request.method,
      headers = request.headers or {},
    }
    
    if request.data then
      http_req.source = ls_ltn12.source.string(request.data)
      http_req.headers["content-length"] = http_req.headers["content-length"] or #request.data
    end
    
    if type(request.allow_redirects) ~= "nil" then
      http_req.redirect = request.allow_redirects
    end
    
    if request.cookies then
      http_req.headers["cookie"] = request.cookies
    end
    
    http.TIMEOUT = (request.timeout or 1)*60
    
    --luacheck: push ignore 211
    local success,statuscode, headers, statusline = http.request(http_req)
    --luacheck: pop
    ls_body = table.concat(ls_body)
    
    if success then
      local respond = {
        code = statuscode,
        body = ls_body,
        headers = headers
      }
      
      if headers["set-cookie"] then
        respond.set_cookies = headers["set-cookie"]
      end
      
      web_channel:push("respond")
      web_channel:push(respond)
    else
      web_channel:push("failed")
      web_channel:push(tostring(statuscode))
    end
  end
end

print("- Web thread terminated")