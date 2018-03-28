--Games runtime API

local rt = {}

function rt.loadResources()
  local scripts = fs.getDirectoryItems("C:/Runtime/Resources/")
  
  for id, name in ipairs(scripts) do
    scripts[id] = fs.load("C:/Runtime/Resources/"..name)
  end
  
  return scripts
end

function rt.loadGlobals()
  local scripts = fs.getDirectoryItems("C:/Runtime/Globals/")
  
  for id, name in ipairs(scripts) do
    scripts[id] = fs.load("C:/Runtime/Globals/"..name)
  end
  
  return scripts
end

function rt.loadGame()
  
  local glob = _FreshGlobals()
glob._G = glob --Magic ;)
  
  local resources = rt.loadResources()
  local globals = rt.loadGlobals()
  
  --Execute the resources
  for i=1, #resources do
    resources[i](glob)
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
  
  return glob, co, chunk
end

function rt.resetEnvironment()
  pal() palt() cam() clip()
  
  clearEStack()
  clearMatrixStack()
  colorPalette() --Reset the color palette.
  patternFill()
  
  TC.setInput(false)
  Audio.stop()
end

function rt.runGame(glob,co,...)
  
  if isMobile() then TC.setInput(true) end
  textinput(not isMobile())
  
  local lastArgs = {...}
  while true do
    if coroutine.status(co) == "dead" then break end
    
    local args = {coroutine.resume(co,unpack(lastArgs))}
    if not args[1] then
      local err = tostring(args[2])
      
      if err:sub(1,12) == '[string ""]:' then
        err = err:sub(13,-1)
      end
      
      rt.resetEnvironment()
      
      print("")
      
      return false, "ERR :"..err
    end
    if args[2] then
      if args[2] == "RUN:exit" then break end
      lastArgs = {coroutine.yield(select(2,unpack(args)))}
      if args[2] == "CPU:pullEvent" or args[2] == "CPU:rawPullEvent" or args[2] == "GPU:flip" or args[2] == "CPU:sleep" then
        if args[2] == "GPU:flip" or args[2] == "CPU:sleep" then
          local name, key = rawPullEvent()
          if name == "keypressed" and key == "escape" then
            break
          end
        else
          if lastArgs[1] and lastArgs[2] == "keypressed" and lastArgs[3] == "escape" then
            break
          end
        end
      end
    end
  end
  
  rt.resetEnvironment()
  
  print("")
  
  return true
    
end

return rt