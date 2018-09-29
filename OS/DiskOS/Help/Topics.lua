--Get the help files PATH
local helpPATH = require("Programs.help",true).getHelpPATH()

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
    table.insert(TOPICS,v)
  end
end

return "\\BTopics:\n\n\\6"..table.concat(TOPICS,"\\7, \\6")