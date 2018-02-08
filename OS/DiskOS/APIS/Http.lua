--HTTP API

--Localized Lua Library

--Localized LIKO-12 Peripherals
local web = WEB

--The API
local http = {}

function http.request(url, postData, headers)
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
  
  --Send the web request
  local ticket = WEB.send(url,args)
  
  --Wait for it to arrived
  for event, id, url, data, errnum, errmsg, errline in pullEvent do
    
    --Here it is !
    if event == "webrequest" then
      --Yes, this is the correct package !
      if id == ticket then
        
        if data then
          data.code = tonumber(data.code)
          
          if data.code < 200 or data.code >= 300 then --Too bad...
            cprint("HTTP Failed Request Body: "..tostring(data.body))
            return false, "HTTP Error: "..data.code
          end
          
          return data.body, data --Yay
        else --Oh, no, it failed
          return false, errmsg
        end
        
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
  
  return http.request(url, headers)
end

function http.post(url, postData, headers)
  if not web then return false, "HTTP API Requires WEB Peripheral" end
  
  return http.request(url, headers)
end

function http.urlEncode(str)
  if not web then return url end
  return web.urlEncode(str)
end

--Make the http API a global
_G["http"] = http