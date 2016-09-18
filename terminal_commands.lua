local Terminal = require("terminal")
local function tout(...) Terminal:tout(...) end
local CMD = {}

local function wrap_string(str,ml)
  local lt = api.floor(str:len()/ml+0.99)
  if lt <= 1 then return {str} end
  local t = {}
  for i = 1, lt+1 do
    table.insert(t,str:sub(0,ml-1))
    str=str:sub(ml,-1)
  end
  return t
end

function CMD.help()
  tout("COMMANDS <REQUIRED> [OPTIONAL]",13)
  --tout()
  tout("HELP: SHOW THIS HELP",7)
  tout("NEW: CLEARS THE MEMORY",7)
  tout("RELOAD: RELOADS THE EDITORSHEET",7)
  tout("RUN: RUNS THE CURRENT GAME",7)
  tout("SAVE <NAME>: SAVES THE CURRENT GAME",7)
  tout("LOAD <NAME>: LOADS A GAME",7)
  tout("IMPORT <PATH>: IMPORTS A SPRITESHEET",7)
  tout("EXPORT <PATH>: EXPORTS THE SPRITESHEET",7)
  tout("CLS: CLEARS THE SCREEN",7)
  tout("VER: SHOWS LIKO12'S TITLE",7)
  --tout()
  tout("PRESS ESC TO OPEN THE EDITOR/EXIT THE GAME",9)
  tout("READ LIKO-12.TXT TO GET STARTED !",12)
end

function CMD.cls()
  for i=1, Terminal.linesLimit do tout() end Terminal:setLine(1)
end

function CMD.ver() tout() tout("-[[liko12]]-") tout(_LK12VER,_LK12VERC) end

function CMD.run()
  local sm = require("editor.sprite"):export()
  local cd = require("editor.code"):export()
  local rt = require("runtime")
  local sprsheet = api.SpriteSheet(api.ImageData(sm):image(),24,12)
  local ok, err = rt:loadGame(cd,sprsheet,function(err)
    _auto_exitgame()
    for line,text in ipairs(wrap_string(err,38)) do
      tout(line == 1 and "ERR: "..text or text,9)
    end
    tout("> ",8,true)
  end)
  if not ok then
    _auto_exitgame()
    for line,text in ipairs(wrap_string(err,38)) do
      tout(line == 1 and "ERR: "..text or text,9)
    end
    tout("> ",8,true)
  else
    _auto_switchgame()
  end
end

function CMD.new()
  require("editor.sprite"):load()
  require("editor.code"):load()
  tout("CLEARED MEMORY",7)
end

function CMD.reload()
  api.EditorSheet = api.SpriteSheet(api.Image("/editorsheet.png"),24,12)
  api.loadDefaultCursors()
  tout("RELOADED EDITORSHEET",7)
end

function CMD.save(command,name)
  if not name then tout("PLEASE PROVIDE A NAME TO SAVE",9) return end
  local sm = require("editor.sprite"):export()
  local cd = require("editor.code"):export()
  local saveCode = "local code = [["..cd.."]]\n\n"
  saveCode = saveCode .. "local spritemap = '"..sm.."'\n\n"
  saveCode = saveCode .. "return {code=code,spritemap=spritemap}"
  api.fs.write("/"..(name)..".lk12",saveCode)
  tout("SAVED TO "..(name)..".lk12",12)
end

function CMD.load(command,name)
  if not name then tout("PLEASE PROVIDE A NAME TO LOAD",9) return end
  local code = api.fs.read("/"..name..".lk12")
  if(code) then
    code = loadstring(code)
    setfenv(code,{})
    local data = code()
    api.SpriteMap = api.SpriteSheet(api.ImageData(data.spritemap):image(),24,12)
    require("editor.code"):load(data.code)
    tout("LOADED /"..name..".lk12",12)
  else
    tout("FILE NOT FOUND")
  end
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
