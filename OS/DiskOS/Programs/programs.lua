if select(1,...) and select(1,...) == "-?" then
  printUsage("programs","Prints the list of available programs")
  return
end

local term = require("terminal")
local PATH = term.getPATH()
local programs = {}
for path in string.gmatch(PATH,"(.-);") do
  if fs.exists(path) then
    local files = fs.getDirectoryItems(path)
    for _,file in ipairs(files) do
      if file:sub(-4,-1) == ".lua" then
        programs[file:sub(1,-5)] = true
      end
    end
  end
end


palt(0,false) --Make black opaque

local peri = select(1,...)

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

local tw, th = termSize()
local sw, sh = screenSize()
local msg = "[press any key to continue, q to quit]"
local msglen = msg:len()

local function sprint(text)
  local cx, cy = printCursor()
  if cy < th-2 then print(text.." ",false) return end
  local tlen = text:len()+1
  if cx+tlen+1 >= tw then
    print("") pushColor() color(9)
    print(msg,false) popColor()
    flip()
    local quit = waitkey()
    printCursor(1,th)
    rect(0,sh-9,sw,8,false,0)
    if quit then return true end
    screenshot():image():draw(0,-8)
    printCursor(cx, th-3)
    print(text.." ",false) return
  else
    print(text.." ",false) return
  end
end

for prog, v in pairs(programs) do
  if sprint(prog) then break end
end

print("")