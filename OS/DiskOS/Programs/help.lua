--Liko12 Help System !

local helpPATH = "C://Help/;"
local function nextPath()
  if helpPATH:sub(-1)~=";" then helpPATH=helpPATH..";" end
  return helpPATH:gmatch("(.-);")
end

local topic = select(1,...)
topic = topic or "Welcome"

local giveApi = select(2,...)

if type(giveApi) == "boolean" then --Requesting HELP api
  local api = {}
  
  function api.setHelpPATH(p)
	helpPath = p
  end
  
  function api.getHelpPath()
	return helpPath
  end
  
  return api
end

helpPath = require("C://Programs/help",true).getHelpPath() --A smart way to keep the helpPath

print("") --New line
palt(0,false) --Make black opaque

local doc --The help document to print

for path in nextPath() do
  if fs.exists(path) then
	local files = fs.directoryItems(path)
    for _,file in ipairs(files) do
      if file == topic then
		doc = path..topic break
      end
    end
    if doc then break end
  end
end

if not doc then color(8) print("Help file not found '"..topic.."' !") return end

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

printCursor(1) --Set the x pos to 1 (the start of the screen)

local tw, th = termSize()
local sw, sh = screenSize()
local msg = "[press any key to continue, q to quit]"
local msglen = msg:len()

local function sprint(text) --Smart print with the "press any key to continue" message
  local cx, cy = printCursor()
  
  local txtlen = text:len()
  local txth = math.ceil(txtlen/tw)
  local txtw = text:sub((txth-1)*tw, -1)
  
  if cy + txth < th+1 then print(text) return end
  for i=1, txth do
	printCursor(1)
	if cy + i < th+1 then
	  print(text:sub( (i-1)*tw+1, (i)*tw ))
	else
	  pushColor() color(9)
	  print(msg,false) popColor()
      flip()
      local quit = waitkey()
      printCursor(1,th)
      rect(1,sh-8,sw,8,false,0)
      if quit then return true end
      print(text:sub( (i-1)*tw+1, (i)*tw ))
	end
  end
end

for line in fs.lines(doc) do
  if sprint(line) then break end
end

print("")
