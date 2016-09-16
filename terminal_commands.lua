local Terminal = require("Terminal")
local function tout(...) Terminal:tout(...) end
local CMD = {}

function CMD.help()
  tout("COMMANDS <REQUIRED> [OPTIONAL]",13)
  --tout()
  tout("HELP: SHOW THIS HELP",7)
  tout("LOAD [PATH]: LOADS THE SPRITESHEET",7)
  tout("SAVE <PATH>: SAVES THE SPRITESHEET",7)
  tout("CLEAR: CLEARS THE SCREEN",7)
  tout("VERSION: SHOWS THE CONSOLE VERSION",7)
  --tout()
  tout("PRESS ESC TO OPEN THE EDITOR",9)
end

function CMD.clear()
  for i=1, Terminal.linesLimit do tout() end Terminal:setLine(1)
end

function CMD.version() tout() tout("-[[liko12]]-") tout("V0.0.1 DEV",9) end

function CMD.save(command,path)
  require("Editor.sprite"):save(path)
  tout("SAVED TO /"..path..".PNG",12)
end

function CMD.load(command,path)
  require("Editor.sprite"):load(path)
  if path then
    tout("LOADED /"..path..".PNG",12)
  else
    tout("CLEARED THE SPRITESHEET",7)
  end
end


return CMD