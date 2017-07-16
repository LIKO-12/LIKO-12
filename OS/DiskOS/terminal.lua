--The terminal !--
local PATH = "D:/Programs/;C:/Programs/;"
local curdrive, curdir, curpath = "D", "/", "D:/"

local editor = require("C://Editors")

local function nextPath(p)
  if p:sub(-1)~=";" then p=p..";" end
  return p:gmatch("(.-);")
end

local fw, fh = fontSize()

local history = {}
local hispos
local btimer, btime, blink = 0, 0.5, true

local function checkCursor()
  local cx, cy = printCursor()
  local tw, th = termSize()
  if cx > tw then cx = tw end
  if cx < 0 then cx = 0 end
  if cy > th then cy = th end
  if cy < 0 then cy = 0 end
  printCursor(cx,cy,0)
  rect(cx*(fw+1)+1,blink and cy*(fh+2)+1 or cy*(fh+2),fw+1,blink and fh or fh+3,false,blink and 4 or 0) --The blink
end

local function split(str)
  local t = {}
  for val in str:gmatch("%S+") do
    table.insert(t, val)
  end
  return unpack(t)
end

local term = {}

function term.init()
  clear() fs.drive("D")
  SpriteGroup(25,1,1,5,1,1,1,0,editor.editorsheet)
  printCursor(0,1,0)
  color(9) print("PRE",5*8+1,3) flip() sleep(0.125)
  cam("translate",0,3) color(12) print("D",false) color(6) print("isk",false) color(12) print("OS",false) color(6) cam("translate",0,-1) print("  0.6") editor.editorsheet:draw(60,(fw+1)*6+1,fh+2) flip() sleep(0.125) cam()
  color(6) print("\nhttp://github.com/ramilego4game/liko12")
  flip() sleep(0.0625)
  if fs.exists("autoexec.lua") then
    term.executeFile("autoexec.lua")
  else
    color(9) print("TYPE HELP FOR HELP")
    flip() sleep(0.0625)
  end
end

function term.setdrive(d)
  if type(d) ~= "string" then return error("DriveLetter must be a string, provided: "..type(d)) end
  if not fs.drives()[d] then return error("Drive '"..d.."' doesn't exists !") end
  curdrive = d
  curpath = curdrive..":/"..curdir
end

function term.setdirectory(d)
  if type(d) ~= "string" then return error("Directory must be a string, provided: "..type(d)) end
  local p = term.resolve(d)
  if not fs.exists(p) then return error("Directory doesn't exists !") end
  if not fs.isDirectory(p) then return error("It must be a directory, not a file") end
  term.setpath(p)
end

function term.setpath(p)
  if type(p) ~= "string" then return error("Path must be a string, provided: "..type(p)) end
  p = term.resolve(p)
  if not fs.exists(p) then return error("Directory doesn't exists !") end
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
  if not chunk then color(8) print("\nL-ERR:"..tostring(err)) color(7) return false, tostring(err) end
  local ok, err = pcall(chunk,...)
  if not ok then color(8) print("\nERR: "..tostring(err)) color(7) return false, tostring(err) end
  if not fs.exists(curpath) then curdir, curpath = "/", curdrive..":/" end
end

function term.execute(command,...)
  if not command then return false, "No command" end
  command = string.lower(command)
  if fs.exists(curpath..command..".lua") then
    term.executeFile(curpath..command..".lua",...)
    color(8) pal() palt() cam() clip() return true
  end
  for path in nextPath(PATH) do
    if fs.exists(path) then
      local files = fs.directoryItems(path)
      for _,file in ipairs(files) do
        if file == command..".lua" then
          term.executeFile(path..file,...)
          textinput(true)
          color(7) pal() palt() cam() clip() return true
        end
      end
    end
  end
  color(9) print("Command not found: " .. command) color(7) return false, "Command not found"
end

function term.loop() --Enter the while loop of the terminal
  term.init()
  cursor("none")
  clearEStack()
  checkCursor() term.prompt()
  local buffer = ""
  while true do
    checkCursor()
    local event, a, b, c, d, e, f = pullEvent()
    if event == "textinput" then
      buffer = buffer..a
      print(a,false)
    elseif event == "keypressed" then
      if a == "return" then
        if hispos then table.remove(history,#history) hispos = false end
        table.insert(history, buffer)
        blink = false; checkCursor()
        print("") -- insert newline after Enter
        term.execute(split(buffer)) buffer = ""
        checkCursor() term.prompt() blink = true cursor("none")
      elseif a == "backspace" then
        blink = false; checkCursor()
        if buffer:len() > 0 then
          buffer = buffer:sub(0,-2)
          printBackspace()
        end
        blink = true; checkCursor()
      elseif a == "delete" then
        blink = false; checkCursor()
        for i=1,buffer:len() do
          printBackspace()
        end
        buffer = ""
        blink = true; checkCursor()
      elseif a == "escape" then
        local screenbk = screenshot()
        local oldx, oldy, oldbk = printCursor()
        editor:loop() cursor("none")
        printCursor(oldx,oldy,oldbk)
        palt(0,false) screenbk:image():draw(0,0) color(7) palt(0,true)
      elseif a == "up" then
        if not hispos then
          table.insert(history,buffer)
          hispos = #history
        end

        if hispos > 1 then
          hispos = hispos-1
          blink = false; checkCursor()
          for i=1,buffer:len() do
            printBackspace()
          end
          buffer = history[hispos]
          for char in string.gmatch(buffer,".") do
            print(char,false)
          end
          blink = true; checkCursor()
        end
      elseif a == "down" then
        if hispos and hispos < #history then
          hispos = hispos+1
          blink = false; checkCursor()
          for i=1,buffer:len() do
            printBackspace()
          end
          buffer = history[hispos]
          for char in string.gmatch(buffer,".") do
            print(char,false)
          end
          if hispos == #history then table.remove(history,#history) hispos = false end
          blink = true; checkCursor()
        end
      end
    elseif event == "touchpressed" then
      textinput(true)
    elseif event == "update" then
      btimer = btimer + a
      if btimer > btime then
        btimer = btimer-btime
        blink = not blink
      end
    end
  end
end

return term
