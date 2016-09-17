local Terminal = require("Terminal")
local function tout(...) Terminal:tout(...) end
local CMD = {}

function CMD.help()
  tout("COMMANDS <REQUIRED> [OPTIONAL]",13)
  --tout()
  tout("HELP: SHOW THIS HELP",7)
  tout("NEW: CLEARS THE MEMORY",7)
  tout("RELOAD: RELOADS THE EDITORSHEET",7)
  tout("IMPORT <PATH>: IMPORTS A SPRITESHEET",7)
  tout("EXPORT <PATH>: EXPORTS THE SPRITESHEET",7)
  tout("CLEAR: CLEARS THE SCREEN",7)
  tout("VERSION: SHOWS THE CONSOLE VERSION",7)
  --tout()
  tout("PRESS ESC TO OPEN THE EDITOR",9)
end

function CMD.clear()
  for i=1, Terminal.linesLimit do tout() end Terminal:setLine(1)
end

function CMD.version() tout() tout("-[[liko12]]-") tout("V0.0.1 DEV",9) end

function CMD.new()
  require("editor.sprite"):load()
  tout("CLEARED MEMORY",7)
end

function CMD.reload()
  require("editor").Sheet = SpriteSheet(Image("/editorsheet.png"),24,12)
  tout("RELOADED EDITORSHEET",7)
end

function CMD.export(command,path)
  require("editor.sprite"):save(path)
  tout("SAVED TO /"..path..".PNG",12)
end

function CMD.import(command,path)
  require("editor.sprite"):load(path)
  tout("LOADED /"..path..".PNG",12)
end


return CMD
