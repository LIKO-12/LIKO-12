--Liko12 Help System !

local helpPATH = "C://Help/;C://Help/GPU/"
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

palt(0,false) --Make black opaque

local doc --The help document to print

for path in nextPath() do
  if fs.exists(path..topic) then
    doc = path..topic break
  elseif fs.exists(path..topic..".md") then
    doc = path..topic..".md" break
  end
end

if not doc then color(8) print("Help file not found '"..topic.."' !") return end

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
local sw, sh = screenSize()
local _, top = printCursor()
local msg = "[press any key to continue, q to quit]"
local msglen = msg:len()

-- Smart print with the "press any key to continue" message
-- Returns true if "q" was pressed, which should abort the process
local function sprint(text)
  local cx, cy = printCursor()
  
  local cleantext = text:gsub("%^%x",""):gsub("%^%^","%^")
  local txtlen = cleantext:len()
  local txth = math.ceil(txtlen/tw)
  local txtw = cleantext:sub((txth-1)*tw, -1)
  
  text = "^7"..text

  -- print text directly if it won't scroll the content past the screen
  if top - txth > 0 then
    for col, txt in string.gmatch(text,"%^%x(.-)") do
      cprint(tostring(col).."  "..tostring(txt))
      color(col) print(txt,false)
    end
    print("")
    top = top - txth
    sleep(0.02) -- a short delay helps following the output
    return
  end
  
  local plines = {}
  local iter = string.gmatch(text,".")
  local curline = { {"",7} }
  for char in iter do
    local flag = true
    if char == "^" then
      local n = iter()
      if n ~= "^" then
        flag = false
        local col = string.match(n,"%x")
        table.insert(curline, {"",col} )
      end
    end
    
    if flag then
      curline[#curline][1] = curline[#curline][1]..char
      if curline[#curline][1]:len() == tw then
        table.insert(plines,curline)
        curline = { {"",7} }
      end
    end
  end
  
  local nextline = ipairs(plines)
  
  for i=1, txth do
    printCursor(0)
    if cy + i >= th then
      pushColor() color(9)
      print(msg,false) popColor()
      flip()
      local quit = waitkey()
      printCursor(0,th-1)
      rect(0,sh-9,sw,8,false,0)
      if quit then return true end
    end
    
    local lk, nline = nextline()
    for k,v in ipairs(nline) do
      color(v[2]) print(v[1],false)
    end
    print("")
    --print(cleantext:sub( (i-1)*tw+1, (i)*tw ))
  end
end

local md = (doc:sub(-3,-1) == ".md")
local doc = fs.read(doc)
doc = doc:gsub("\r\n","\n")
if doc:sub(-1,-1) ~= "\n" then doc = doc .. "\n" end

--Clear markdown
if md then
  doc = doc:gsub("%-%-%-","")
  doc = doc:gsub("```lua","")
  doc = doc:gsub("```","")
  doc = doc:gsub("# ","")
  doc = doc:gsub("#","")
  doc = doc:gsub("%*%*","")
  doc = doc:gsub("__","")
  doc = doc:gsub("\\>",">")
  
  while doc:find("\n\n\n") do
    doc = doc:gsub("\n\n\n","\n\n")
  end
end

for line in string.gmatch(doc,"(.-)\n") do
  if sprint(line) then break end
end

print("")
