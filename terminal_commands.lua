local Terminal = require("Terminal")
local function tout(...) Terminal:tout(...) end
local CMD = {}

function CMD.help()
  tout("COMMANDS <REQUIRED> [OPTIONAL]",13)
  --tout()
  tout("HELP: SHOW THIS HELP",7)
  tout("NEW: CLEARS THE MEMORY",7)
  tout("RELOAD: RELOADS THE EDITORSHEET",7)
  tout("SAVE <NAME>: SAVES THE CURRENT GAME",7)
  tout("LOAD <NAME>: LOADS A GAME",7)
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
  require("editor.code"):load()
  tout("CLEARED MEMORY",7)
end

function CMD.reload()
  EditorSheet = SpriteSheet(Image("/editorsheet.png"),24,12)
  loadDefaultCursors()
  tout("RELOADED EDITORSHEET",7)
end

function CMD.save(command,name)
  if not name then tout("PLEASE PROVIDE A NAME TO SAVE",9) return end
  local sm = require("editor.sprite"):export()
  local cd = require("editor.code")
  cd = cd:export()
  local saveCode = "local code = [["..cd.."]]\n\n"
  saveCode = saveCode .. "local spritemap = '"..sm.."'\n\n"
  saveCode = saveCode .. "return {code=code,spritemap=spritemap}"
  FS.write("/"..(name)..".lk12",saveCode)
  tout("SAVED TO "..(name)..".lk12",12)
end

function CMD.load(command,name)
  if not name then tout("PLEASE PROVIDE A NAME TO LOAD",9) return end
  local code = FS.read("/"..name..".lk12")
  code = loadstring(code)
  setfenv(code,{})
  local data = code()
  SpriteMap = SpriteSheet(ImageData(data.spritemap):image(),24,12)
  require("editor.code"):load(data.code)
  tout("LOADED /"..name..".lk12",12)
end

function CMD.export(command,path)
  require("editor.sprite"):export(path)
  tout("EXPORTED TO /"..path..".PNG",12)
end

function CMD.import(command,path)
  require("editor.sprite"):load(path)
  tout("IMPORTED /"..path..".PNG",12)
end


return CMD