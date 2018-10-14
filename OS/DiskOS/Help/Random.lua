--Get the help files PATH
local helpPATH = require("Programs.help",true).getHelpPATH()
local term = require("terminal")

--Create an iterator for the helpPATH
local function nextPath()
  if helpPATH:sub(-1)~=";" then helpPATH=helpPATH..";" end
  return helpPATH:gmatch("(.-);")
end

local TOPICS = {}

for path in nextPath() do
  local ptopics = fs.getDirectoryItems(path)
  for k,v in ipairs(ptopics) do
    if v:sub(-4,-1) == ".lua" then v = v:sub(1,-5) end
    if v ~= "Random" then table.insert(TOPICS,v) end
  end
end

local id = math.random(1,#TOPICS)

term.execute("help",TOPICS[id])

return false