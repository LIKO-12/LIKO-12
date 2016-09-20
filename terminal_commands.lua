local term = require("terminal")
local function tout(...) term:tout(...) end
local CMD = {}

function CMD.help()
  tout("COMMANDS <REQUIRED> [OPTIONAL]",13)
  --tout()
  tout("HELP: SHOW THIS HELP",7)
  tout("NEW: CLEARS THE MEMORY",7)
  tout("RELOAD: RELOADS THE EDITORSHEET",7)
  tout("RUN: RUNS THE CURRENT GAME",7)
  tout("SAVE <NAME>: SAVES THE CURRENT GAME",7)
  tout("LOAD <NAME> [args]: LOADS A GAME",7)
  tout("IMPORT <PATH>: IMPORTS A SPRITESHEET",7)
  tout("EXPORT <PATH>: EXPORTS THE SPRITESHEET",7)
  tout("CLS: CLEARS THE SCREEN",7)
  tout("VER: SHOWS LIKO12'S TITLE",7)
  --tout()
  tout("PRESS ESC TO OPEN THE EDITOR/EXIT THE GAME",9)
  tout("READ LIKO-12.TXT TO GET STARTED !",12)
end

function CMD.cls()
  for i=1, term.linesLimit do tout() end term:setLine(1)
end

function CMD.ver() tout() tout("-[[liko12]]-") tout(_LK12VER,_LK12VERC) end

function CMD.run()
  local sm = require("editor.sprite"):export()
  local cd = require("editor.code"):export()
  local rt = require("runtime")
  local sprsheet = api.SpriteSheet(api.ImageData(sm):image(),24,12)
  local ok, err = rt:loadGame(cd,sprsheet,function(err)
    _auto_exitgame()
    tout("ERR: "..err,9)
    tout(term.rootDir.."> ",8,true)
  end)
  if not ok then
    _auto_exitgame()
    tout("ERR: "..err,9)
    tout(term.rootDir.."> ",8,true)
  else
    _auto_switchgame()
  end
end

function CMD.new()
  require("editor.sprite"):load()
  require("editor.code"):load()
  require("editor").lastCart = nil
  require("editor").lastSprpng = nil
  tout("CLEARED MEMORY",7)
end

function CMD.reload()
  api.EditorSheet = api.SpriteSheet(api.Image("/editorsheet.png"),24,12)
  api.loadDefaultCursors()
  tout("RELOADED EDITORSHEET",7)
end

function CMD.save(command,name)
  local name = name or require("editor").lastCart
  if not name then tout("PLEASE PROVIDE A NAME TO SAVE",9) return end
  local sm = require("editor.sprite"):export()
  local cd = require("editor.code"):export()
  local saveCode = "local code = [["..cd.."]]\n\n"
  saveCode = saveCode .. "local spritemap = '"..sm.."'\n\n"
  saveCode = saveCode .. "return {code=code,spritemap=spritemap}"
  local ok, err = api.fs.write((name)..".lk12",saveCode)
  if ok then
    tout("SAVED TO "..term.rootDir..(name)..".lk12",12)
  else
    tout("ERR: "..err,9)
  end
  require("editor").lastCart = name
end

function CMD.load(command,name,...)
  if not name then tout("PLEASE PROVIDE A NAME TO LOAD",9) return end
  if not api.fs.exists(term.rootDir..name..".lk12") then tout(term.rootDir..name..".lk12 DOES NOT EXISTS !",9) return end
  local code = api.fs.read(term.rootDir..name..".lk12")
  local chunk, err = loadstring(code)
  if not chunk then tout("ERR: "..err,9) return end
  local args = {...}
  setfenv(chunk,{})
  local ok, data = pcall(chunk,unpack(args))
  if not ok then tout("ERR: "..data,9) return end
  api.SpriteMap = api.SpriteSheet(api.ImageData(data.spritemap):image(),24,12)
  require("editor").lastsprpng = nil
  require("editor.code"):load(data.code)
  tout("LOADED "..term.rootDir..name..".lk12",12)
  require("editor").lastCart = name
end

function CMD.export(command,path)
  local path = path or require("editor").lastSprpng
  if not path then tout("PLEASE PROVIDE A PATH TO EXPORT TO",9) return end
  require("editor.sprite"):export(path)
  tout("EXPORTED TO "..path..".PNG",12)
end

function CMD.import(command,path)
  if not path then tout("PLEASE PROVIDE A PATH TO IMPORT FROM",9) return end
  if not love.filesystem.exists(path..".png") then tout(path..".png DOES NOT EXISTS !") return end
  require("editor.sprite"):load(path)
  tout("IMPORTED /"..path..".PNG",12)
  require("editor").lastSprpng = path
end

function CMD.cd(command,path)
  if not path then tout("PLEASE PROVIDE A PATH FIRST",9) return end
  local curpath = path:sub(0,1) == "/" and path.."/" or term.rootDir..path.."/"
  if path == ".." then curpath = "/" end
  if not api.fs.exists(curpath) then tout(curpath.." DOES NOT EXISTS !",9) return end
  if not api.fs.isDir(curpath) then tout(path.." IS NOT A DIRECTORY !",9) return end
  term.rootDir = curpath
end

function CMD.mkdir(command,path)
  if not path then tout("PLEASE PROVIDE A PATH FIRST",9) return end
  local curpath = path:sub(0,1) == "/" and path or term.rootDir..path
  if api.fs.exists(curpath) then tout(path.." ALREADY EXISTS !",9) return end
  local ok, err = api.fs.mkDir(curpath)
  if ok then
    tout("MAKED DIRECTORY SUCCESSFULLY",12)
  else
    tout("ERR: "..err,9)
  end
end

function CMD.dir(command,path)
  local path = path or ""
  local curpath = path:sub(0,1) == "/" and path.."/" or term.rootDir..path.."/"
  local files = api.fs.dirItems(curpath)
  local dirstring = ""
  local filestring = ""
  for k,v in ipairs(files) do
    if api.fs.isDir(curpath..v) then
      dirstring = dirstring.." "..v
    else
      filestring = filestring.." "..v
    end
  end
  if dirstring ~= "" then tout(dirstring,12) end
  if filestring ~= "" then tout(filestring,8) end
end

CMD.ls = CMD.dir

function CMD.del(command,path)
  if not path then tout("PLEASE PROVIDE A PATH FIRST",9) return end
  local curpath = term.rootDir..path
  if not api.fs.exists(curpath) then tout(curpath.." DOES NOT EXISTS !",9) return end
  local ok, err = api.fs.del(curpath)
  if ok then
    tout("DELETED "..path.." SUCCESSFULLY",12)
  else
    tout("ERR: "..(err or "UNKNOWN"),9)
  end
  if not love.filesystem.exists("/data/") then love.filesystem.createDirectory("/data/") end
end

return CMD