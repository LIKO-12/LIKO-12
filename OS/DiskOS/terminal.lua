--The terminal !--
local _LIKO_TAG = _LVer.tag
local _LIKO_DEV = (_LIKO_TAG == "Development")
local _LIKO_PRE = (_LIKO_TAG == "Pre-Release")
local _LIKO_BUILD = _LVer.major ..".".. _LVer.minor ..".".. _LVer.patch

local PATH = "D:/Programs/;C:/Programs/;" --The system PATH variable, used by the terminal to search for programs.
local curdrive, curdir, curpath = "D", "/", "D:/" --The current active path in the terminal.

--Add the sub-directories.
for id, dirName in ipairs(fs.getDirectoryItems("C:/Programs/")) do
  if fs.isDirectory("C:/Programs/"..dirName) then
    PATH = PATH.."C:/Programs/"..dirName.."/;"
  end
end

local editor --The editors api, will be loaded later in term.init()

--Creates an iterator which returns each path in the PATH provided.
local function nextPath(p)
  if p:sub(-1)~=";" then p=p..";" end
  return p:gmatch("(.-);")
end

local fw, fh = fontSize() --The LIKO-12 GPU Font size.

local history = {} --The history of commands.
local hispos --The current item in the history.
local btimer, btime, blink = 0, 0.5, true  --The terminal cursor blink timer.
local ecommand --The editor command, used by the Ctrl-R hotkey to execute the 'run' program.
local buffer = "" --The terminal input buffer
local inputPos = 1 --The next input character position in the terminal buffer.

--Used for autocomplete suggestion
local commands = {}
local autocompleteSuggestions = {}
local suggestionIndex = nil

--Checks if the cursor is in the bounds of the screen.
local function checkCursor()
  local cx, cy = printCursor()
  local tw, th = termSize()
  if cx > tw then cx = tw end
  if cx < 0 then cx = 0 end
  if cy > th then cy = th end
  if cy < 0 then cy = 0 end
  printCursor(cx,cy,0)
  rect(cx*(fw+1)+1,blink and cy*(fh+1)+1 or cy*(fh+1),fw+1,blink and fh-1 or fh+2,false,blink and 4 or 0) --The blink
  if inputPos <= buffer:len() then
    printCursor(cx,cy,-1)
    print(buffer:sub(inputPos,inputPos),false)
    printCursor(cx,cy,0)
  end
end

--Splits a string at each white space.
local function split(str)
  local t = {}
  for val in str:gmatch("%S+") do
    table.insert(t, val)
  end
  return unpack(t)
end

local term = {} --The terminal API

function term.init()
  editor = require("Editors") --Load the editors
  clear()
  SpriteGroup(25,1,1,5,1,1,1,0,_SystemSheet)
  printCursor(0,1,0)
  color(_LIKO_DEV and 8 or (_LIKO_PRE and 9 or 11)) print(_LIKO_TAG,5*8+1,3)
  flip() sleep(0.125)
  color(7) print("V".._LIKO_BUILD,(_LIKO_DEV or _LIKO_PRE) and 53 or 43,10)
  cam("translate",0,3) color(12) print("D",false) color(6) print("isk",false) color(12) print("OS") color(6) cam()
  _SystemSheet:draw(60,(fw+1)*6+1,fh+3) flip() sleep(0.125)
  color(6) print("\nhttp://github.com/ramilego4game/liko12")

  flip() sleep(0.0625)
  if fs.exists("D:/autoexec.lua") then
    term.executeFile("D:/autoexec.lua")
  elseif fs.exists("C:/autoexec.lua") then
    term.executeFile("C:/autoexec.lua")
  else
    if _LIKO_Old then
      color(7) print("\n Updated LIKO-12 Successfully.\n Type ",false)
      color(6) print("help Whatsnew",false)
      color(7) print(" for changelog.\n")
    else
      term.execute("tip")
    end
    color(9) print("Type help for help")
    flip() sleep(0.0625)
  end

  commands = term.updateCommands()
end

--Reload the system
function term.reload()
  --Backup the loaded game and the active editor
  local game_data = editor:export()
  local api_version = editor.apiVersion
  local game_path = editor.filePath
  local active_editor = editor.active

  package.loaded = {} --Reset the package system
  package.loaded[_SystemDrive..":/terminal.lua"] = term --Restore the current terminal instance

  --Reload the APIS
  for k, file in ipairs(fs.getDirectoryItems(_SystemDrive..":/APIS/")) do
    dofile(_SystemDrive..":/APIS/"..file)
  end

  editor = require("Editors") --Re initialize the editors

  --Restore the loaded game and the active editor
  editor:import(game_data)
  editor.apiVersion = api_version
  editor.filePath = game_path
  editor.active = active_editor
end

function term.setdrive(d)
  if type(d) ~= "string" then return error("DriveLetter must be a string, provided: "..type(d)) end
  if not fs.drives()[d] then return error("Drive '"..d.."' doesn't exist !") end
  curdrive = d
  curpath = curdrive..":/"..curdir
end

function term.setdirectory(d)
  if type(d) ~= "string" then return error("Directory must be a string, provided: "..type(d)) end
  local p = term.resolve(d)
  if not fs.exists(p) then return error("Directory doesn't exist !") end
  if not fs.isDirectory(p) then return error("It must be a directory, not a file") end
  term.setpath(p)
end

function term.setpath(p)
  if type(p) ~= "string" then return error("Path must be a string, provided: "..type(p)) end
  p = term.resolve(p)
  if not fs.exists(p) then return error("Directory doesn't exist !") end
  if not fs.isDirectory(p) then return error("It must be a directory, not a file") end
  local drive, path
  if p:sub(-2,-1) == ":/" then
    drive = p:sub(1,-3)
    path = ""
  else
    drive,path = p:match("(.+):/(.+)")
  end
  if p:sub(-1,-1) ~= "/" then p = p.."/" end

  curdrive, curdir, curpath = drive, "/"..path, p
end

function term.getpath() return curpath end
function term.getdrive() return curdrive end
function term.getdirectory() return curdir end

function term.setPATH(p) PATH = p end
function term.getPATH() return PATH end

function term.prompt()
  color(7) print(term.getpath().."> ",false)
end

function term.resolve(path)
  path = path:gsub("\\","/") --Windows users :P

  if path:sub(-1,-1) == ":" then -- C:
    path = path.."/"
    return path, fs.exists(path)
  end

  if path:sub(-2,-1) == ":/" then -- C:/
    return path, fs.exists(path)
  end

  if not path:match("(.+):/(.+)") then
    if path:sub(1,1) == "/" then -- /Programs
      path = curdrive..":"..path
    else
      if curpath:sub(-1,-1) == "/" then
        path = curpath..path -- Demos/bump
      else
        path = curpath.."/"..path -- Demos/bump
      end
    end
  end

  local d, p = path:match("(.+):/(.+)") --C:/./Programs/../Editors
  if d and p then
    p = "/"..p.."/"; local dirs = {}
    p = p:gsub("/","//"):sub(2,-1)
    for dir in string.gmatch(p,"/(.-)/") do
      if dir == "." then
        --Do nothing, it's useless
      elseif dir == ".." then
        if #dirs > 0 then
          table.remove(dirs,#dirs) --remove the last directory
        end
      elseif dir ~= "" then
        table.insert(dirs,dir)
      end
    end

    path = d..":/"..table.concat(dirs,"/")
    return path, fs.exists(path)
  end
end

function term.executeFile(file,...)
  local chunk, err = fs.load(file)
  if not chunk then color(7) return 3, "\nL-ERR:"..tostring(err) end
  local ok, err, e = pcall(chunk,...)
  color(7) pal() palt() cam() clip() patternFill()
  if not ok then color(7) cprint("Program Error:",err) return 2, "\nERR: "..tostring(err) end
  if not fs.drives()[curdrive] then curdrive, curdir, curpath = _SystemDrive, "/", _SystemDrive..":/" end
  if not fs.exists(curpath) then curdir, curpath = "/", curdrive..":/" end
  return tonumber(err) or 0, e
end

--[[
Exit codes:
-----------
0 -> Success
1 -> Failure
2 -> Execution Error
3 -> Compilation Error
4 -> Command not found 404
]]

function term.execute(command,...)
  if not command then return 4, "No command" end
  if fs.exists(curpath..command..".lua") then
    local exitCode, err = term.executeFile(curpath..command..".lua",...)
    if exitCode > 0 then color(8) print(err or "Failed !") color(7) end
    textinput(true)
    return exitCode, err
  end
  for path in nextPath(PATH) do
    if fs.exists(path) then
      local files = fs.getDirectoryItems(path)
      for _,file in ipairs(files) do
        if file == command..".lua" then
          local exitCode, err = term.executeFile(path..file,...)
          if exitCode > 0 then color(8) print(err or "Failed !") color(7) end
          textinput(true)
          return exitCode, err
        end
      end
    end
  end
  color(9) print("Command not found: " .. command) color(7) return 4, "Command not found"
end

function term.ecommand(command) --Editor post command
	ecommand = command
end

local function splitFilePath(path) return path:match("(.-)([^\\/]-%.?([^%.\\/]*))$") end --A function to split path to path, name, extension.

function term.loop() --Enter the while loop of the terminal
  cursor("none")
  clearEStack()
  checkCursor() term.prompt()
  buffer, inputPos = "", 1
  for event, a,b,c,d,e,f in pullEvent do
    --If an autocomplete suggestion is displayed, doesn't make the cursor blink
    if not autocompleteSuggestions[1] then
      checkCursor() --Which also draws the cursor blink
    end

    if event == "filedropped" then
      local p, n, e = splitFilePath(a)
      if e == "png" or e == "lk12" then
        if b then
          fs.write(_SystemDrive..":/.temp/"..n,b)
          blink = false; checkCursor()
          print("load "..n)
          term.execute("load",_SystemDrive..":/.temp/"..n)
          term.prompt()
          blink = true; checkCursor()
        else
          blink = false; checkCursor()
          print("load "..n)
          color(8) print("Failed to read file.") color(7)
          term.prompt()
          blink = true; checkCursor()
        end
      end
    elseif event == "textinput" then
      print(a..buffer:sub(inputPos,-1),false)
      for i=inputPos,buffer:len() do printBackspace(-1) end
      buffer = buffer:sub(1,inputPos-1)..a..buffer:sub(inputPos,-1)
      inputPos = inputPos + a:len()
    elseif event == "keypressed" then
      if a == "return" then
        if autocompleteSuggestions[1] then
          term.acceptSuggestion()
        else
          if hispos then table.remove(history,#history) hispos = false end
          table.insert(history, buffer)
          blink = false; checkCursor()
          print("") -- insert newline after Enter
          term.execute(split(buffer)) buffer, inputPos = "", 1
          commands = term.updateCommands()
          checkCursor() term.prompt() blink = true cursor("none")
        end
      elseif a == "backspace" then
        --If an autocomplete suggestion is displayed, erase it
        if autocompleteSuggestions[1] then
          term.refuseSuggestion()
        else
          blink = false; checkCursor()
          if buffer:len() > 0 then
            --Remove the character
            printBackspace()

            --Re print the buffer
            for char in string.gmatch(buffer:sub(inputPos,-1),".") do
              print(char,false)
            end

            --Erase the last character
            print("-",false) printBackspace()

            --Go back to the input position
            for i=#buffer,inputPos,-1 do
              printBackspace(-1)
            end

            --Remove the character from the buffer
            buffer = buffer:sub(1,inputPos-2) .. buffer:sub(inputPos,-1)

            --Update input postion
            inputPos = inputPos-1
          end
          blink = true; checkCursor()
        end
      elseif a == "delete" then
        --If an autocomplete suggestion is displayed, erase it
        if autocompleteSuggestions[1] then
          term.refuseSuggestion()
        else
          blink = false; checkCursor()
          print(buffer:sub(inputPos,-1),false)
          for i=1,buffer:len() do
            printBackspace()
          end
          buffer, inputPos = "", 1
          blink = true; checkCursor()
        end
      elseif a == "escape" then
        local screenbk = screenshot()
        local oldx, oldy, oldbk = printCursor()
        editor:loop() cursor("none")
        printCursor(oldx,oldy,oldbk)
        palt(0,false) screenbk:image():draw(0,0) color(7) palt(0,true) flip()
        if ecommand then
          term.execute(split(ecommand))
          checkCursor() term.prompt() blink = true cursor("none")
          ecommand = false
        end
      elseif a == "up" then
        if not hispos then
          table.insert(history,buffer)
          hispos = #history
        end

        if hispos > 1 then
          hispos = hispos-1
          blink = false; checkCursor()
          print(buffer:sub(inputPos,-1),false)
          for i=1,buffer:len() do
            printBackspace()
          end
          buffer = history[hispos]
          inputPos = buffer:len() + 1
          for char in string.gmatch(buffer,".") do
            print(char,false)
          end
          blink = true; checkCursor()
        end
      elseif a == "down" then
        if hispos and hispos < #history then
          hispos = hispos+1
          blink = false; checkCursor()
          print(buffer:sub(inputPos,-1),false)
          for i=1,buffer:len() do
            printBackspace()
          end
          buffer = history[hispos]
          inputPos = buffer:len() + 1
          for char in string.gmatch(buffer,".") do
            print(char,false)
          end
          if hispos == #history then table.remove(history,#history) hispos = false end
          blink = true; checkCursor()
        end
      elseif a == "left" then
        --If an autocomplete suggestion is displayed, erase it
        if autocompleteSuggestions[1] then
          term.refuseSuggestion()
        else
          blink = false; checkCursor()
          if inputPos > 1 then
            inputPos = inputPos - 1
            printBackspace(-1)
          end
          blink = true; checkCursor()
        end
      elseif a == "right" then
        --If an autocomplete suggestion is displayed, accept it
        if autocompleteSuggestions[1] then
          term.acceptSuggestion()
        else
          blink = false; checkCursor()
          if inputPos <= buffer:len() then
            print(buffer:sub(inputPos,inputPos),false)
            inputPos = inputPos + 1
          end
        end
        blink = true; checkCursor()
      elseif a == "c" then
        if isKDown("lctrl","rctrl") then
          clipboard(buffer)
        end
      elseif a == "v" then
        if isKDown("lctrl","rctrl") then
          local paste = clipboard() or ""

          for char in string.gmatch(paste..buffer:sub(inputPos,-1),".") do
            print(char,false)
          end

          for i=inputPos,buffer:len() do printBackspace(-1) end

          buffer = buffer:sub(1,inputPos-1)..paste..buffer:sub(inputPos,-1)
          inputPos = inputPos + paste:len()
        end
      elseif a == "tab" then
        --If the autocomplete suggestions list is empty, create a new one
        if not autocompleteSuggestions[1] then
          autocompleteSuggestions = term.autocomplete(buffer, commands)
          suggestionIndex
         = 1
        --Otherwise, go to the next suggestion in the list (looping to the
        --first if the end of the list is reached)
        else
          term.clearSuggestion(autocompleteSuggestions[suggestionIndex])
          suggestionIndex = suggestionIndex + 1
          if not autocompleteSuggestions[suggestionIndex] then
            suggestionIndex= 1
          end
        end
        --Display the current suggestion
        if autocompleteSuggestions[1] then
          term.displaySuggestion(autocompleteSuggestions[suggestionIndex])
        end
      end
    elseif event == "touchpressed" then
      textinput(true)
    elseif event == "update" then
      btimer = btimer + a
      if btimer > btime then
        btimer = btimer%btime
        blink = not blink
      end
    end
  end
end

--Given an input and a list of commands, return a list of strings that can be
--used as autocomplete suggestion. For example if passed "c" and {"cls, copy"}
--as parameters, will return {"ls", "opy"}.
function term.autocomplete(input, commands)

  result = {}
  for k, f in ipairs(commands) do
    if f:sub(1, input:len()) == input and input:len() < f:len() then
      result[#result + 1] = f:sub(#input + 1)
    end
  end

  return result
end

--Accept the currently displayed suggestion and empty the suggestions list
function term.acceptSuggestion()
  term.append(autocompleteSuggestions[suggestionIndex])
  autocompleteSuggestions = {}
end

--Display given suggestion on the command line
function term.displaySuggestion(suggestion)
  local cx, cy = printCursor()
  local fw, fh = fontSize()
  local x, y = 1+(fw+1)*cx, 1+(fh+1)*cy
  rect(x-1,y-1,#suggestion*(fw+1)+1,fh+2,false,5)
  print(suggestion,x,y)
end

--Delete the currently displayed suggestion and empty the suggestions list
function term.refuseSuggestion()
  term.clearSuggestion(autocompleteSuggestions[suggestionIndex])
  autocompleteSuggestions = {}
end

--Clear given suggestion from the command line
function term.clearSuggestion(suggestion)
  local cx, cy = printCursor()
  local x, y = 1+(fw+1)*cx, 1+(fh+1)*cy
  rect(x-1,y-1,#suggestion*(fw+1)+1,fh+2,false,0)
end

--Append given text to the command line
function term.append(text)
  print(text..buffer:sub(inputPos,-1), false, true)
  for i=inputPos, buffer:len() do printBackspace(-1) end
  buffer = buffer:sub(1,inputPos-1)..text..buffer:sub(inputPos,-1)
  inputPos = inputPos + text:len()
end

function term.updateCommands()
  commands = term.indexCommandsPATH()
  commands = tableConcat(commands, term.indexCommandsActiveDir())
  return commands
end

--Return a list of commands found in PATH
function term.indexCommandsPATH()
  commands = {}
  for path in nextPath(PATH) do
    if fs.exists(path) then
      local files = fs.getDirectoryItems(path)
      for _,file in ipairs(files) do
        if file:sub(#file-3) == ".lua" then
          table.insert(commands, file:sub(1,#file-4))
        end
      end
    end
  end
  return commands
end

function term.indexCommandsActiveDir()
  commands = {}
  local files = fs.getDirectoryItems(term.getpath())
  for _,file in ipairs(files) do
    if file:sub(#file-3) == ".lua" then
      table.insert(commands, file:sub(1,#file-4))
    end
  end
  return commands
end

--An helper used to concatenate the list of commands in PATH and the list of
--commands in the active directory. This could probably be moved somewhere else
--in the code.
function tableConcat(t1,t2)
  for i=1,#t2 do
      t1[#t1+1] = t2[i]
  end
  return t1
end

return term
