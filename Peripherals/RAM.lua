--[[
Layout (96 KB)
--------------
0x0000 Meta Data (736 Bytes)
0x02E0 SpriteMap (12 KB)
0x32E0 Flags Data (288 Bytes)
0x3400 MapData (18 KB)
0x7C00 Sound Tracks (13 KB)
0xB000 Compressed Lua Code (20 KB)
0x10000 Persistant Data (2 KB)
0x10800 GPIO (128 Bytes)
0x10880 Reserved (768 Bytes)
0x10B80 Draw State (64 Bytes)
0x10BC0 Reserved (64 Bytes)
0x10C00 Free Space (1 KB)
0x11000 Reserved (4 KB)
0x12000 Label Image (12 KBytes)
0x15000 VRAM (12 KBytes)
0x18000 End of memory (Out of range)

Meta Data (1 KB)
----------------
0x0000 Data Length (6 Bytes)
0x0006 LIKO-12 Header (7 Bytes)
0x000D Color Palette (64 Bytes)
0x004D Disk Version (1 Byte)
0x004E Disk Meta (1 Byte)
0x004F Screen Width (2 Bytes)
0x0051 Screen Hight (2 Bytes)
0x0053 Reserved (1 Byte)
0x0054 SpriteMap Address (4 Bytes)
0x0058 MapData Address (4 Bytes)
0x005C Instruments Data Address (4 Bytes)
0x0060 Tracks Data Address (4 Bytes)
0x0064 Tracks Orders Address (4 Bytes)
0x0068 Compressed Lua Code Address (4 Bytes)
0x006C Author Name (16 Bytes)
0x007C Game Name (16 Bytes)
0x008C SpriteSheet Width (2 Bytes)
0x008E SpriteSheet Height (2 Bytes)
0x0090 Map Width (1 Byte)
0x0091 Map height (1 Byte)
0x0093 Reserved (594 Bytes)

Disk META:
--------------
1. Auto event loop.
2. Activate controllers.
3. Keyboad Only.
4. Mobile Friendly.
5. Static Resolution.
6. Compatibilty Mode.
7. Write Protection.
8. Licensed Under CC0.
]]

--luacheck: ignore 421 422

return function(config)
  local ramsize = 0 --The current size of the ram
  local ram = {} --The RAM table (Only affected by the default handler)
  
  local handlers = {} --The active ram handlers system
  local layout = config.layout or {{88*1024}} --Defaults to a 88KB RAM.
  
  local devkit = {} --The devkit of the RAM
  
  --function to convert a number into a hex string.
  local function tohex(a) return string.format("0x%X",a or 0) end
  
  function devkit.addHandler(startAddress, endAddress, handler)
    if type(startAddress) ~= "number" then return error("Start address must be a number, provided: "..type(startAddress)) end
    if type(endAddress) ~= "number" then return error("End address must be a number, provided: "..type(endAddress)) end
    if type(handler) ~= "function" then return error("Handler must be a function, provided: "..type(handler)) end
    
    table.insert(handlers,{startAddr = startAddress, endAddr = endAddress, handler = handler})
  end
  
  --A binary handler.
  function devkit.defaultHandler(mode,startAddress,...)
    local args = {...}
    if mode == "poke" then
      local address, value = args[1], args[2]
      ram[address] = value
    elseif mode == "poke4" then
      local address4, value = args[1], args[2]
      local address = math.floor(address4 / 2)
      local byte = ram[address]
      
      if address4 % 2 == 0 then --left nibble
        byte = bit.band(byte,0x0F)
        value = bit.rshift(value,4)
        byte = bit.bor(byte,value)
      else --right nibble
        byte = bit.band(byte,0xF0)
        byte = bit.bor(byte,value)
      end
      
      ram[address] = byte
    elseif mode == "peek" then
      local address = args[1]
      return ram[address]
    elseif mode == "peek4" then
      local address4 = args[1]
      local address = math.floor(address4 / 2)
      local byte = ram[address]
      
      if address4 % 2 == 0 then --left nibble
        byte = bit.lshift(byte,4)
      else --right nibble
        byte = bit.band(byte,0x0F)
      end
      
      return byte
    elseif mode == "memcpy" then
      local from, to, len = args[1], args[2], args[3]
      for i=0,len-1 do
        ram[to+i] = ram[from+i]
      end
    elseif mode == "memset" then
      local address, value = args[1], args[2]
      local len = value:len()
      for i=0,len-1 do
        ram[address+i] = string.byte(value,i+1)
      end
    elseif mode == "memget" then
      local address, len = args[1], args[2]
      local subtable,nextid = {}, 1
      for i=address,address+len-1 do
        subtable[nextid] = ram[i]
        nextid = nextid + 1
      end
      if len > 255 then
        for i=1,nextid-1 do
          subtable[i] = string.char(subtable[i])
        end
        return table.concat(subtable)
      else
        return string.char(unpack(subtable))
      end
    end
  end
  
  --Build the layout.
  for k, section in ipairs(layout) do
    local size = section[1]
    local handler = section[2] or devkit.defaultHandler
    
    local startAddress = ramsize
    ramsize = ramsize + size
    local endAddress = ramsize-1
    print("Layout ["..k.."]: "..tohex(startAddress).." -> ".. tohex(endAddress))
    devkit.addHandler(startAddress,endAddress,handler)
    
    --Extend the ram table
    for i=#ram, #ram+size do
      ram[i] = 0
    end
  end
  ram[#ram] = nil --Remove the last address.
  
  local lastaddr = string.format("0x%X",ramsize-1) --The last accessible ram address.
  local lastaddr4 = string.format("0x%X",(ramsize-1)*2) --The last accessible ram address for peek4 and poke4.
  
  local function Verify(value,name,etype,allowNil)
    if type(value) ~= etype then
      if allowNil then
        error(name.." should be a "..etype.." or a nil, provided: "..type(value),3)
      else
        error(name.." should be a "..etype..", provided: "..type(value),3)
      end
    end
    
    if etype == "number" then
      return math.floor(value)
    end
  end
  
  local api, yapi = {}, {}
  
  --API Start
  function api.poke4(address,value)
    address = Verify(address,"Address","number")
    value = Verify(value,"Value","number")
    
    if address < 0 or address > (ramsize-1)*2 then return error("Address out of range ("..tohex(address*2).."), must be in range [0x0,"..lastaddr4.."]") end
    if value < 0 or value > 15 then return error("Value out of range ("..value..") must be in range [0,15]") end
    
    for k,h in ipairs(handlers) do
      if address <= h.endAddr*2+1 then
        h.handler("poke4",h.startAddr*2,address,value)
        return
      end
    end
  end
  
  function api.poke(address,value)
    address = Verify(address,"Address","number")
    value = Verify(value,"Value","number")
    
    if address < 0 or address > ramsize-1 then return error("Address out of range ("..tohex(address).."), must be in range [0x0,"..lastaddr.."]") end
    if value < 0 or value > 255 then return error("Value out of range ("..value..") must be in range [0,255]") end
    
    for k,h in ipairs(handlers) do
      if address <= h.endAddr then
        h.handler("poke",h.startAddr,address,value)
        return
      end
    end
  end
  
  function api.peek4(address)
    address = Verify(address,"Address","number")
    
    if address < 0 or address > (ramsize-1)*2 then return error("Address out of range ("..tohex(address*2).."), must be in range [0x0,"..lastaddr4.."]") end
    
    for k,h in ipairs(handlers) do
      if address <= h.endAddr*2+1 then
        local v = h.handler("peek4",h.startAddr*2,address)
        return v --It ran successfully
      end
    end
    
    return 0 --No handler is found
  end
  
  function api.peek(address)
    address = Verify(address,"Address","number")
    
    if address < 0 or address > ramsize-1 then return error("Address out of range ("..tohex(address).."), must be in range [0x0,"..lastaddr.."]") end
    
    for k,h in ipairs(handlers) do
      if address <= h.endAddr then
        local v = h.handler("peek",h.startAddr,address)
        return v --It ran successfully
      end
    end
    
    return 0 --No handler is found
  end
  
  function api.memget(address,length)
    address = Verify(address,"Address","number")
    length = Verify(length,"Length","number")
    
    if address < 0 or address > ramsize-1 then return error("Address out of range ("..tohex(address).."), must be in range [0x0,"..lastaddr.."]") end
    if length <= 0 then return error("Length must be bigger than 0") end
    if address+length > ramsize then return error("Length out of range ("..length..")") end
    local endAddress = address+length-1
    
    local str = ""
    for k,h in ipairs(handlers) do
      if endAddress >= h.startAddr then
        if address <= h.endAddr then
          local sa, ea = address, endAddress
          if sa < h.startAddr then sa = h.startAddr end
          if ea > h.endAddr then ea = h.endAddr end
          local data = h.handler("memget",h.startAddr,sa,ea-sa+1)
          str = str .. data
        end
      end
    end
    
    return str
  end
  
  function api.memset(address,data)
    address = Verify(address,"Address","number")
    Verify(data,"Data","string")
    
    if address < 0 or address > ramsize-1 then return error("Address out of range ("..tohex(address).."), must be in range [0x0,"..lastaddr.."]") end
    local length = data:len()
    if length == 0 then return error("Cannot set empty string") end
    if address+length > ramsize then return error("Data too long to fit in the memory ("..length.." character)") end
    local endAddress = address+length-1
    
    for k,h in ipairs(handlers) do
      if endAddress >= h.startAddr then
        if address <= h.endAddr then
          local sa, ea = address, endAddress
          if sa < h.startAddr then sa = h.startAddr end
          if ea > h.endAddr then ea = h.endAddr end
          local d = data:sub(sa-address+1,ea-address+1)
          h.handler("memset",h.startAddr,sa,d)
        end
      end
    end
  end
  
  function api.memcpy(from_address,to_address,length)
    from_address = Verify(from_address,"Source Address","number")
    to_address = Verify(to_address,"Destination Address","number")
    length = Verify(length,"Length","number")
    
    if from_address < 0 or from_address > ramsize-1 then return error("Source Address out of range ("..tohex(from_address).."), must be in range [0x0,"..tohex(ramsize-2).."]") end
    if to_address < 0 or to_address > ramsize then return error("Destination Address out of range ("..tohex(to_address).."), must be in range [0x0,"..lastaddr.."]") end
    if length <= 0 then return error("Length should be bigger than 0") end
    if from_address+length > ramsize then return error("Length out of range ("..length..")") end
    if to_address+length > ramsize then length = ramsize-to_address end
    local from_end = from_address+length-1
    local to_end = to_address+length-1
    
    for k1,h1 in ipairs(handlers) do
      if from_end >= h1.startAddr and from_address <= h1.endAddr then
        local sa1, ea1 = from_address, from_end
        if sa1 < h1.startAddr then sa1 = h1.startAddr end
        if ea1 > h1.endAddr then ea1 = h1.endAddr end
        local to_address = to_address + (sa1 - from_address)
        local to_end = to_end + (ea1 - from_end)
        for k2,h2 in ipairs(handlers) do
          if to_end >= h2.startAddr and to_address <= h2.endAddr then
            local sa2, ea2 = to_address, to_end
            if sa2 < h2.startAddr then sa2 = h2.startAddr end
            if ea2 > h2.endAddr then ea2 = h2.endAddr end
            
            local sa1 = sa1 + (sa2 - to_address)
            --local ea1 = sa1 + (ea2 - to_end)
            
            if h1.handler == h2.handler then --Direct Copy
              h1.handler("memcpy",h1.startAddr,sa1,sa2,ea2-sa2+1)
            else --InDirect Copy
              local d = h1.handler("memget",h1.startAddr,sa1,ea2-sa2+1)
              h2.handler("memset",h2.startAddr,sa2,d)
            end
          end
        end
      end
    end
  end
  
  devkit.ramsize = ramsize
  devkit.ram = ram
  devkit.tohex = tohex
  devkit.layout = layout
  devkit.handlers = handlers
  devkit.api = api
  
  return api, yapi, devkit
end