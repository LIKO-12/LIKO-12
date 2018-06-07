if select(1,...) and select(1,...) == "-?" then
  printUsage("programs","Prints the list of available programs")
  return
end

local sw, sh = screenSize()
local tw, th = termSize()
local msg = "[press any key to continue, q to quit]"

local term = require("terminal")
local PATH = term.getPATH()
local programs = {}
for path in string.gmatch(PATH,"(.-);") do
  if fs.exists(path) then
    local files = fs.getDirectoryItems(path)
    for id,file in ipairs(files) do
      if file:sub(-4,-1) == ".lua" then
        programs[#programs+1] = file:sub(1,-5)
      end
    end
  end
end

table.sort(programs)

local listString = table.concat(programs,", ")

local maxWidth, wrapped = wrapText(listString,sw)

flip() clearEStack()

color(11) print("Available Programs:\n")

for lineNumber, line in ipairs(wrapped) do
  color(6 + lineNumber%2)
  print(line)
  
  local cx, cy = printCursor()
  if cy == th-1 then
    local terminate = false
    
    color(9) print(msg,false)
    
    for event, a,b,c,d,e,f in pullEvent do
      if event == "keypressed" then
        break
      elseif event == "textinput" then
        if string.lower(a) == "q" then
          terminate = true
          break
        end
      elseif event == "touchpressed" then
        textinput(true)
      end
    end
    
    for i=1, #msg do
      printBackspace()
    end
    
    if terminate then break end
  end
end

print("")

flip() clearEStack()