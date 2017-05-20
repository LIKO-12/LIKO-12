return function(config)
  local ramsize = config.size or 80*1024 --Defaults to 80 KBytes.
  local ram = string.rep("\0",ramsize)
  
  local devkit = {}
  local api = {}
  
  function api:poke(address,value)
    
  end
  
  function api:peek(address)
    
  end
  
  function api:memget(address,length)
    
  end
  
  function api:memset(address,data)
    
  end
  
  function api:memcpy(from_address,to_address,length)
    
  end
  
  devkit.ramsize = ramsize
  setmetatable(devkit,{
    __index = function(t,k)
      if k == "ram" then return ram end
    end
  })
  
  return api, devkit
end