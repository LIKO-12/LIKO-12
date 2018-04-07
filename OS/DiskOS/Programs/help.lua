--Liko12 Help System !
if select(1,...) == "-?" then
  printUsage(
    "help","Displays the help info",
    "help <topic>", "Displays a help topic"
  )
  return
end

local lume = require("Libraries.lume")

local helpPATH = "C:/Help/;C:/Manual/Help/"
local function nextPath()
  if helpPATH:sub(-1)~=";" then helpPATH=helpPATH..";" end
  return helpPATH:gmatch("(.-);")
end

local topic = select(1,...)
topic = topic or "Welcome"

local giveApi = select(1,...)

if type(giveApi) == "boolean" then --Requesting HELP api
  local api = {}

  function api.setHelpPATH(p)
    helpPATH = p
  end

  function api.getHelpPath()
    return helpPATH
  end

  return api
end

helpPATH = require("Programs.help",true).getHelpPath() --A smart way to keep the helpPath

palt(0,false) --Make black opaque

local doc --The help document to print

for path in nextPath() do
  if fs.exists(path..topic) then
    doc = path..topic break
  elseif fs.exists(path..topic..".lua") then
    doc = path..topic..".lua" break
  end
end

if not doc then return 1, "Help file not found '"..topic.."' !" end

-- Waits for any input (keyboard or mouse) to continue
-- Returns true if "q" was pressed, to quit
local function waitkey()
  while true do
    local name, a = pullEvent()
    if name == "keypressed" then
      return false
    elseif name == "textinput" then
      if string.lower(a) == "q" then return true else return end
    elseif name == "touchpressed" then
      textinput(true)
    end
  end
end

printCursor(0) --Set the x pos to 0 (the start of the screen)

local tw, th = termSize()
local msg = "[press any key to continue, q to quit]"
local msglen = msg:len()
local skipY = select(2,printCursor())

-- Smart print with the "press any key to continue" message
-- Returns true if "q" was pressed, which should abort the process
local function sprint(text)
  if text == "" then text = " " end
  
  local iter = text:gmatch(".")
  
  local curX, curY = printCursor()
  
  skipY = skipY - 1
  
  for char in iter do
    if char == "\\"  then
      local nchar = iter()
      if nchar == "\\" then
        print(nchar,false)
      else
        color(tonumber(nchar,16))
        curX = curX - 1
      end
    elseif char == "\n" then
      print(char,false)
      curX = tw-1 --A new line :o
    else
      print(char,false)
    end
    
    curX = curX + 1
    
    if curX == tw then --End of line
      curX, curY = 0, curY+1
      
      if curY == th then
        curY = th-1
        sleep(0.02)
        if skipY > 0 then
          skipY = skipY - 1
        else
          pushColor() color(9)
          print(msg,false) flip()
          local quit = waitkey()
          for i=1,msglen do printBackspace() end
          popColor()
          if quit then return true end
        end
      end
    end
    
  end
end

local lua = (doc:sub(-4,-1) == ".lua")
if lua then
  fs.load(doc)()
  print("")
  return 0
end

local doc = fs.read(doc)
doc = doc:gsub("\r\n","\n")
doc = doc:gsub("\\LIKO%-12","\\CL\\8I\\BK\\9O\\7-\\F12")

color(7)

sprint(doc)

print("")