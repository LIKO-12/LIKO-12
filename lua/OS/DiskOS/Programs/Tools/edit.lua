--Text editor--
local args = {...} --Get the arguments passed to this program
if #args < 1 or args[1] == "-?" then
  printUsage(
    "edit <file>","The file to edit in the text editor."
  )
  return
end

local tar = table.concat(args," ") --The path may include whitespaces
local term = require("terminal")
tar = term.resolve(tar)

local highlighter = require("Libraries.SyntaxHighlighter")

if fs.exists(tar) and fs.isDirectory(tar) then return 1, "Can't edit directories !" end
if fs.isReadonly(tar) and not fs.exists(tar) then return 1, "Directory is readonly !" end
local eutils = require("Editors.utils")
local tool = eutils:newTool(fs.isReadonly(tar))

local ok, editor = assert(pcall(assert(fs.load(_SystemDrive..":/Editors/code.lua")),tool))
if tar:sub(-4,-1) ~= ".lua" and tar:sub(-5,-1) ~= ".json" then editor.colorize = false end
if tar:sub(-5,-1) == ".json" then highlighter:setSyntax("json") end
editor.readonly = fs.isReadonly(tar)

local data --Data to import at start.
if fs.exists(tar) then
  data = fs.read(tar):gsub("\r\n","\n")
end

local function reload(tool)
  if fs.exists(tar) then tool.editor:import(fs.read(tar)) end
  _systemMessage("Reloaded successfully",1)
end

local function save(tool)
  local ndata = tool.editor:export()
  local ok, err = pcall(fs.write,tar,ndata)
  if ok then
    _systemMessage("Saved successfully",1)
  else
    _systemMessage("Failed: "..err,5,9,4)
  end
end

local function hotkey(tool,key,sc)
  if sc == "ctrl-r" then --Run the file
    local bkframe = screenshot() --Backup the screen
    local px, py, px = printCursor() --Backup the printing cursor
    pushMatrix() --Backup the matrix
    pushPalette() --Backup the palette
    pushColor() --Backup the current color
    
    cam() --Reset the camera.
    pal() palt() --Reset the palettes.
    printCursor(0,0,0) --Reset the printing cursor.
    clear() --Clear the screen.
    color(7) --Set the active color to white.
    
    if tool.editor.colorize then --If it's a Lua file
      local code = tool.editor:export() --Get the Lua code.
      local chunk, cerr = loadstring(code)
      if not chunk then
        color(8)
        print("CERR: "..tostring(cerr))
      else
        local ok, err = pcall(chunk)
        if not ok then
          color(8)
          print("ERR: "..tostring(err))
        end
      end
      color(9)
      print("[Press any key to continue]",false) flip()
      
      local kflag
      for event, a in pullEvent do
        if event == "keypressed" then
          kflag = a
        elseif event == "keyreleased" and kflag and kflag == a then
          break
        end
      end
    end
    
    cam() --Reset the camera.
    pal() palt() --Reset the palettes.
    clear() --Clear the screen.
    
    bkframe:image():draw() --Restore the screen frame
    
    popColor() --Restore the color
    popPalette() --Restore the palette
    popMatrix() --Restore the matrix
    printCursor(px,py,pc) --Restore the printing cursor
    
    return true
  end
end

tool:start(editor,reload,save,data,hotkey)

highlighter:setSyntax("lua") --Make sure the highlighter is back into Lua