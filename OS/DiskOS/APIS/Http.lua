--HTTP API

if not WEB then return end --WEB Peripheral not available

--Localized Lua Library

--Localized LIKO-12 Peripherals
local web = WEB

--Luasocket libraries
local ls_url = web.luasocket("socket.url")

--The API
local http = {}

function http.request(url, postData, headers, method)
  if not web then return false, "HTTP API Requires WEB Peripheral" end
  
  --The request arguments.
  local args = {}
  
  --The request header.
  args.headers = headers
  
  --POST method
  if postData then
    args.method = "POST"
    args.data = tostring(postData)
  end
  
  --Set method
  args.method = method or args.method
  
  --Send the web request
  local ticket = WEB.request(url,args)
  
  --Wait for it to arrived
  for event, id, data in pullEvent do
    
    if event == "HTTP_Respond" then --Here it is !
      --Yes, this is the correct package !
      if id == ticket then
        data.code = tonumber(data.code)
        
        if data.code < 200 or data.code >= 300 then --Too bad...
          --cprint("HTTP Failed Request Body: "..tostring(data.body))
          return false, "HTTP Error: "..data.code, data
        end
        
        return data.body, data --Yay
      end
    elseif event == "HTTP_Failed" then
      if id == ticket then
        return false, data
      end
    elseif event == "keypressed" then
      
      if id == "escape" then
        return false, "Request Canceled" --Well, the user changed his mind
      end
      
    end
  end
end

function http.get(url, headers)
  if not web then return false, "HTTP API Requires WEB Peripheral" end
  
  return http.request(url, false, headers)
end

function http.post(url, postData, headers)
  if not web then return false, "HTTP API Requires WEB Peripheral" end
  
  return http.request(url, postData, headers)
end

function http.urlEscape(str)
  return ls_url.escape(tostring(str))
end

function http.urlEncode(data)
  local encode = {}
  
  for k,v in pairs(data) do
    encode[#encode + 1] = k.."="..v
  end
  
  return table.concat(encode,"&")
end

--Make the http API a global
_G["http"] = http