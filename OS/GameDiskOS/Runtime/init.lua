--Games runtime API

local rt = {}

function rt.loadResources()
  local scripts = fs.getDirectoryItems(_SystemDrive..":/Runtime/Resources/")
  
  for id, name in ipairs(scripts) do
    scripts[id] = fs.load(_SystemDrive..":/Runtime/Resources/"..name)
  end
  
  return scripts
end

function rt.loadGlobals()
  local scripts = fs.getDirectoryItems(_SystemDrive..":/Runtime/Globals/")
  
  for id, name in ipairs(scripts) do
    scripts[id] = fs.load(_SystemDrive..":/Runtime/Globals/"..name)
  end
  
  return scripts
end

function rt.loadGame(edata,apiver)
  
  apiver = apiver or (edata and 1 or require("Editors").apiVersion)
  edata = edata or (require("Editors"):export())
  
  local glob = _FreshGlobals()
  glob._G = glob --Magic ;)
  
  local resources = rt.loadResources()
  local globals = rt.loadGlobals()
  
  --Execute the resources
  for i=1, #resources do
    resources[i](glob,edata)
  end
  
  --Load the lua code
  local chunk, cerr = loadstring(glob._GameCode,"")
  
  if not chunk then
    cerr = tostring(cerr)
    
    if cerr:sub(1,12) == '[string ""]:' then
      cerr = cerr:sub(13,-1)
    end
    
    return false, "Compile ERR :"..cerr
  end
  
  --Set the sandbox
  setfenv(chunk, glob)
  
  --Create the coroutine
  local co = coroutine.create(chunk)
  
  --Execute the globals constructors
  for i=1, #globals do
    globals[i](glob,co)
  end
  
  --Apply compatiblity layers if needed
  if apiver < _APIVer then
    for a=_APIVer-1, apiver, -1 do
      if fs.exists(_SystemDrive..":/Runtime/Compatibility/v"..a..".lua") then
        fs.load(_SystemDrive..":/Runtime/Compatibility/v"..a..".lua")(glob,co)
      end
    end
  end
  
  glob._APIVer = apiver --The api version the game is running under.
  
  return glob, co, chunk
end

function rt.resetEnvironment()
  pal() palt() cam() clip()
  
  clearEStack()
  clearMatrixStack()
  colorPalette() --Reset the color palette.
  patternFill()
  
  TC.setInput(false)
  if Audio then Audio.stop() end
end

function rt.runGame(glob,co,...)
  
  --Enable the touch controls on mobile
  if isMobile() then TC.setInput(true) end
  textinput(not isMobile()) --And disable the touch keyboard
  
  --The event loop coroutine, created in the 01_Lua.lua script
  local evco = glob.__evco; glob.__evco = nil
  
  local pause = glob.pause --Backup the pause function
  
  local lastArgs = {...}
  while true do
    if coroutine.status(co) == "dead" then
      if evco then
        co = evco; evco = false --So it doesn't get placed again.
      else
        break
      end
    end
    
    local args = {coroutine.resume(co,unpack(lastArgs))}
    
    --Program crashed
    if not args[1] then
      local err = tostring(args[2])
      if err:sub(1,12) == '[string ""]:' then err = err:sub(13,-1) end
      rt.resetEnvironment(); print("")
      return false, "ERR :"..err
    end
    
    --Nope, it's alive :-)
    if args[2] then
      
      --Special command for exiting the game
      if args[2] == "RUN:exit" then
        rt.resetEnvironment(); print("")
        if args[3] then
          return false, tostring(args[3])
        else
          return true
        end
        
        --Capture the keypressed event
      elseif args[2] == "CPU:pullEvent" or args[2] == "CPU:rawPullEvent" then
        lastArgs = {coroutine.yield(select(2,unpack(args)))}
        
        local event, a,b,c,d,e,f = select(2,unpack(lastArgs))
        
        --Check for the escape key
        if event == "keypressed" and a == "escape" then
          rt.resetEnvironment(); print(""); return true
        elseif event == "keypressed" and a == "return" then
          pause()
        end
        
        --Hack the sleep command
      elseif args[2] == "CPU:sleep" then
        local timer = args[3] --The sleep timer
        
        if type(timer) ~= "number" or timer < 0 then
          lastArgs = {coroutine.yield(select(2,unpack(args)))} --Let the original sleep blame the programmer.
        else
          while timer > 0 do
            local event, a,b,c,d,e,f = rawPullEvent()
            
            if event == "update" then
              timer = timer - a
            elseif event == "keypressed" and a == "escape" then
              rt.resetEnvironment(); print(""); return true
            elseif event == "keypressed" and a == "return" then
              pause()
            else
              triggerEvent(event, a,b,c,d,e,f)
            end
          end
          
          lastArgs = {true} --Sleep ran successfully
        end
        
        --Hack the flip command
      elseif args[2] == "CPU:flip" then
        _hasFlipped() --Clear the flip flag
        while true do
          local event, a,b,c,d,e,f = rawPullEvent()
          
          if event == "keypressed" and a == "escape" then
            rt.resetEnvironment(); print(""); return true
          elseif event == "keypressed" and a == "return" then
            pause()
          end
          
          triggerEvent(event, a,b,c,d,e,f)
          
          if _hasFlipped() then break end
        end
        
        lastArgs = {true} --Sleep ran successfully
        
        --Run the rest of the commands normally
      else
        lastArgs = {coroutine.yield(select(2,unpack(args)))}
      end
      
    end
  end
  
  rt.resetEnvironment()
  
  print("")
  
  return true
    
end

return rt