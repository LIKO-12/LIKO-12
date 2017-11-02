  local IMGWidth, IMGHeight, OnChange, OnCall = ...
  
  local IMG
  
  local IMGLine = IMGWidth/2
  local IMGLine4 = IMGWidth
  local IMGSize = IMGLine*IMGHeight
  local IMGSize4 = IMGLine4*IMGHeight
  
  local band,bor,lshift,rshift = bit.band,bit.bor,bit.lshift,bit.rshift
  
  return function(mode,startAddress,address,...)
    address = address - startAddress
    if OnCall and mode ~= "setImage" then OnCall() end
    if mode == "setImage" then
      
      IMG = ...
      
    elseif mode == "poke" then
      
      local pix = ...
      
      --Calculate the position of the left pixel
      local x = (address % IMGLine) * 2
      local y = math.floor(address / IMGLine)
      
      --Separate the 2 pixels from each other
      local lpix = band(pix,0xF0)
      local rpix = band(pix,0x0F)
      
      --Shift the left pixel
      lpix = rshift(lpix,4)
      
      --Set the pixels
      IMG:setPixel(x,y,lpix,0,0,255)
      IMG:setPixel(x+1,y,rpix,0,0,255)
      
      --Tell that it has been changed.
      OnChange()
      
    elseif mode == "poke4" then
      
      local pix = ...
      
      --Calculate the position of the left pixel
      local x = address % IMGLine4
      local y = math.floor(address / IMGLine4)
      
      --Set the pixels
      IMG:setPixel(x,y,pix,0,0,255)
      
      --Tell that it has been changed.
      OnChange()
      
    elseif mode == "peek" then
      
      --Calculate the position of the left pixel
      local x = (address % IMGLine) * 2
      local y = math.floor(address / IMGLine)
      
      --Get the colors of the 2 pixels
      local lpix = IMG:getPixel(x,y)
      local rpix = IMG:getPixel(x+1,y)
      
      --Shift the left pixel.
      lpix = lshift(lpix,4)
      
      --Merge the 2 pixels into 1 byte.
      local pix = bor(lpix,rpix)
      
      --Return the final result
      return pix
      
    elseif mode == "peek4" then
      
      --Calculate the position of the left pixel
      local x = address % IMGLine4
      local y = math.floor(address / IMGLine4)
      
      --Return the pixel color
      local pix = IMG:getPixel(x,y)
      return pix
      
    elseif mode == "memget" then
      
      local length = ...
      
      local x = (address % IMGLine) * 2
      local y = math.floor(address / IMGLine)
      
      local xStart, data = x, ""
      
      for Y = y, imgHeight-1 do
        for X = xStart, imgWidth-1, 2 do
          
          local lpix = IMG:getPixel(X,Y)
          local rpix = IMG:getPixel(X+1,Y)
          
          lpix = lshift(lpix,4)
          
          local pix = bor(lpix,rpix)
          local char = string.char(pix)
          
          data = data .. char
          
          length = length -1
          
          if length == 0 then
            return data
          end
          
        end
        xStart = 0 --Trick
      end
      
      return data
      
    elseif mode == "memset" then
      
      local data = ...
      local length = data:len()
      
      local x = (address % IMGLine) * 2
      local y = math.floor(address / IMGLine)
      
      local iter = string.gmatch(data,".")
      
      for i=1,length do
        
        local char = iter()
        local pix = string.byte(char)
        
        local lpix = band(pix,0xF0)
        local rpix = band(pix,0x0F)
        
        lpix = rshift(lpix,4)
        
        IMG:setPixel(x,y,lpix,0,0,255)
        IMG:setPixel(x+1,y,rpix,0,0,255)
        
        x = x+2
        
        if x >= _LIKO_W then
          x = x - _LIKO_W
          y = y+1
        end
        
      end
      
      --Tell that it has been changed.
      OnChange()
      
    elseif mode == "memcpy" then
      
      local toAddress, length = ...
      
      local addressEnd = address+length-1
      local toAddressEnd = toAddress+length-1
      
      for line0=0,IMGSize,IMGLine do
        local line0End = line0+IMGLine-1
        
        if addressEnd >= line0 and address <= line0End then
          local sa1 = (address < line0) and line0 or address
          local ea1 = (addressEnd > line0End) and line0End or addressEnd
          
          local toAddress = toAddress + (sa1 - address)
          local toAddressEnd = toAddressEnd + (ea1 - addressEnd)
          
          for line1=0,IMGSize,IMGLine do
            local line1End = line1+IMGLine-1
            
            if toAddressEnd >= line1 and toAddress <= line1End then
              local sa2 = (toAddress < line1) and line1 or toAddress
              local ea2 = (toAddressEnd > line1End) and line1End or toAddressEnd
              
              local address = address + (sa2 - toAddress)
              local addressEnd = addressEnd + (ea2 - toAddressEnd)
              
              local len = addressEnd - address + 1
              
              local fromX = (address % IMGLine) * 2
              local fromY = math.floor(address / IMGLine)
              
              local toX = (sa2 % IMGLine) * 2
              local toY = math.floor(sa2 / IMGLine)
              
              IMG:paste(IMG,toX,toY,fromX,fromY,len*2,1)
            end
          end
        end
      end
      
      --Tell that it has been changed.
      OnChange()
      
    end
  end