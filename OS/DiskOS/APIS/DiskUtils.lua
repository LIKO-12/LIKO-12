--Disk File (.lk12) Utilities.

--Variables.


--Localized Lua Library


--The API
local DiskUtils = {}

function DiskUtils.encodeDiskGame(edata,ctype,clvl)
  local edata, ctype, clvl = edata or {}, ctype or "none", clvl or 9
  
  --The disk file header, the disk body, the total disk data.
  local header = string.format("LK12;OSData;DiskOS;DiskGame;V%d;%dx%d;C:",_DiskVer,sw,sh)
  
  --Binary encoding.
  if ctype == "bin" then
    local null = BinUtils.Null --0x00 Character
  
    local bHeader, hid = {}, 2 --The header, contains the saveid and the data size.
    local chunks, cid = {}, 1 --The data chunks, has the order of the header.
    local largest = 0 --The largest data chunk size.
    
    for saveId, saveData in pairs(edata) do
      local size = #saveData --The size of the chunk
      largest = largest > size and largest or size --Check if it's larger than the largest.
      
      bHeader[hid] = saveId --The saveid
      bHeader[hid+1] = null --Null terminated
      bHeader[hid+2] = size --The size, currently as number, will be encoded later.
      chunks[cid] = saveData --The data chunk.
      hid, cid = hid+3, cid+1 --Update the next indexes.
    end

    largest = BinUtils.numLength(largest) --Calculate how many bytes are needed to store each size value.

    bHeader[1] = string.char(largest) --Convert it into a character.
    bHeader[hid] = null --Null terminate it, so it's possible to do a "future feature" (more than 1 char for the size length)
    --After digging more in numbers, Lua can't hold integers bigger than 4 bytes (under 32-bit), so this null is useless, we will never ever reach numbers that need 255 bytes to be stored !
    
    --Conver the size values into encoded numbers.
    for id, value in pairs(bHeader) do
      if type(value) == "number" then
        bHeader[id] = BinUtils.numToBin(value,largest) --It's littleEndian, just incase.
      end
    end
    
    return header.."binary;Rev:1;"..table.concat(bHeader)..table.concat(chunks)
    
  --ASCII encoding.
else
    
    local body = {}
    for saveId, saveData in pairs(edata) do
      body[#body+1] = string.format("___%s___\n%s\n",tostring(saveId),saveData:gsub("___",""))
    end
    body = table.concat(body)
    
    --Compression applied
    if ctype ~= "none" then
      local compressedBody = math.compress(body, ctype, clvl)
      local b64Body = math.b64enc(compressedBody)
      
      return string.format("%s%s;CLvl:%d;%s",header,ctype,clvl,b64Body)
      
    --Store
    else
      
      return header.."none;CLvl:0;"..body
    end
  end
end

function DiskUtils.identifyDiskType(diskData)
  if not diskData:sub(0,5) == "LK12;" then return error("This is not a valid LK12 file !!") end
  diskData = diskData:gsub("\r\n","\n")
  
  --LK12;OSData;OSName;DataType;Version;Compression;CompressLevel; data"
  --local header = "LK12;OSData;DiskOS;DiskGame;V"..saveVer..";"..sw.."x"..sh..";C:"
  
  local datasum = 0
  local nextargiter = string.gmatch(diskData,".")
  local function nextarg()
    local start = datasum + 1
    while true do
      datasum = datasum + 1
      local char = nextargiter()
      if not char then datasum = datasum - 1; return end
      if char == ";" then break end
    end
    return diskData:sub(start,datasum-1)
  end
  nextarg() --Skip LK12;
  
  local filetype = nextarg()
  if not filetype then return error("Invalid Data !") end
  return filetype
end

function DiskUtils.decodeDiskGame(diskData)
  if not diskData:sub(0,5) == "LK12;" then return error("This is not a valid LK12 file !!") end
  diskData = diskData:gsub("\r\n","\n")
  
  --LK12;OSData;OSName;DataType;Version;Compression;CompressLevel; data"
  --local header = "LK12;OSData;DiskOS;DiskGame;V"..saveVer..";"..sw.."x"..sh..";C:"
  
  local datasum = 0
  local nextargiter = string.gmatch(diskData,".")
  local function nextarg()
    local start = datasum + 1
    while true do
      datasum = datasum + 1
      local char = nextargiter()
      if not char then datasum = datasum - 1; return end
      if char == ";" then break end
    end
    return diskData:sub(start,datasum-1)
  end
  nextarg() --Skip LK12;
  
  local filetype = nextarg()
  if not filetype then return error("Invalid Data !") end
  if filetype ~= "OSData" then
    return error("Can't load '"..filetype.."' files !")
  end

  local osname = nextarg()
  if not osname then return error("Invalid Data !") end
  if osname ~= "DiskOS" then return error("Can't load files from '"..osname.."' OS !") end

  local datatype = nextarg()
  if not datatype then return error("Invalid Data !") end
  if datatype ~= "DiskGame" then return error("Can't load '"..datatype.."' from '"..osname.."' OS !") end

  local dataver = nextarg()
  if not dataver then return error("Invalid Data !") end
  dataver = tonumber(string.match(dataver,"V(%d+)"))
  if not dataver then return error("Invalid Data !") end
  if dataver > _DiskVer then return error("Can't load disks newer than V".._DiskVer..", provided: V"..dataver) end
  if dataver < _MinDiskVer then return error("Can't load disks older than V".._DiskVer..", provided: V"..dataver..", Use 'update_disk' command to update the disk") end
  
  local sw, sh = screenSize()

  local datares = nextarg()
  if not datares then return error("Invalid Data !") end
  local dataw, datah = string.match(datares,"(%d+)x(%d+)")
  if not (dataw and datah) then return error("Invalid Data !") end dataw, datah = tonumber(dataw), tonumber(datah)
  if dataw ~= sw or datah ~= sh then return error("This disk is made for GPUs with "..dataw.."x"..datah.." resolution, current GPU is "..sw.."x"..sh) end

  local compress = nextarg()
  if not compress then return error("Invalid Data !") end
  compress = string.match(compress,"C:(.+)")
  if not compress then return error("Invalid Data !") end

  if compress == "binary" then
    
    local revision = nextarg()
    if not revision then return error("Invalid Data !") end
    revision = string.match(revision,"Rev:(%d+)")
    if not revision then return error("Invalid Data !") end
    
    revision = tonumber(revision)
    
    if revision < 1 then return error("Can't load binary saves with revision 0 or lower ("..revision..")") end
    if revision > 1 then return error("Can't load binary saves with revision 2 or higher") end
    
    local diskBody = diskData:sub(datasum+1,-1)
    local edata = {}
    
    local iter, counter = BinUtils.binIter(diskBody)
  
    local lengthSize = iter()
    
    local names, nid = {}, 1
    local lengths, lid = {}, 1
    
    --Read the header
    while true do
      local startPos = counter()+1
      while true do
        if iter() == 0 then
          break
        end
      end
      local endPos = counter()-1
      
      local saveid = diskBody:sub(startPos, endPos)
      
      if saveid == "" then break end
      
      for i=1,lengthSize do iter() end
      
      names[nid] = saveid
      lengths[lid] = BinUtils.binToNum(diskBody:sub(endPos+2,endPos+lengthSize+1))
      
      nid, lid = nid+1, lid+1
    end
    
    --Read the chunks
    local cStart = counter()+1
    for i, len in ipairs(lengths) do
      local id = self.saveid[names[i]]
      local chunk = diskBody:sub(cStart, cStart+len-1)
      edata[id] = chunk
      cStart = cStart + len
    end
    
    return edata
    
  else
    
    local clevel = nextarg()
    if not clevel then return error("Invalid Data !") end
    clevel = string.match(clevel,"CLvl:(.+)")
    if not clevel then return error("Invalid Data !") end clevel = tonumber(clevel)

    local diskBody = diskData:sub(datasum+2,-1)

    if compress ~= "none" then --Decompress
      local b64data, char = math.b64dec(diskBody)
      if not b64data then cprint(char) cprint(string.byte(char)) error(tostring(char)) end
      diskBody = math.decompress(b64data,compress,clevel)
    end
    
    local edata = {}
    
    while true do
      local _, saveIdStart = string.find(diskBody,"___")
      if not saveIdStart then break end
      saveIdStart = saveIdStart+1
      
      local saveIdEnd, saveDataStart = string.find(diskBody,"___")
      if not saveIdEnd then break end
      saveIdEnd, saveDataStart = saveIdEnd-1, saveDataStart+1
      
      local saveId, saveData = diskBody:sub(saveIdStart,saveIdEnd)
      
      local saveDataEnd = string.find(diskBody,"___")
      if not saveDataEnd then
        saveData = diskBody:sub(saveDataStart,-1)
        diskBody = ""
      else
        saveDataEnd = saveDataEnd-1
        saveData = diskBody:sub(saveDataStart, saveDataEnd)
        diskBody = diskBody:sub(saveDataEnd+1,-1)
      end
      
      edata[saveId] = saveData
    end
    
    return edata
  end
end

--Make the diskutils a global
_G["DiskUtils"] = DiskUtils