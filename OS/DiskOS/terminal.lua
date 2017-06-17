--The terminal !--
local PATH = "C://Programs/;"
local curdrive, curdir, curpath = "C", "/", "C:///"

local editor = require("C://Editors")

local function nextPath(p)
  if p:sub(-1)~=";" then p=p..";" end
  return p:gmatch("(.-);")
end

local fw, fh = fontSize()

clear()
SpriteGroup(25,1,1,5,1,1,1,0,editor.editorsheet)
printCursor(0,1,0)
color(8) print("DEV",5*8+1,3) flip() sleep(0.125)
cam("translate",0,3) color(12) print("D",false) color(6) print("isk",false) color(12) print("OS",false) color(6) cam("translate",0,-1) print("  0.6") editor.editorsheet:draw(60,(fw+1)*6+1,fh+2) flip() sleep(0.125) cam()
color(6) print("\nhttp://github.com/ramilego4game/liko12")
flip() sleep(0.0625)
color(9) print("TYPE HELP FOR HELP")
flip() sleep(0.0625)

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

function term.setdrive(d)
  if type(d) ~= "string" then return error("DriveLetter must be a string, provided: "..type(d)) end
  if not fs.drives()[d] then return error("Drive '"..d.."' doesn't exists !") end
  curdrive = d
  curpath = curdrive.."://"..curdir
end

function term.setdirectory(d)
  if type(d) ~= "string" then return error("Directory must be a string, provided: "..type(d)) end
  if not fs.exists(curdrive.."://"..d) then return error("Directory doesn't exists !") end
  if not fs.isDirectory(curdrive.."://"..d) then return error("It must be a directory, not a file") end
  if d:sub(0,1) ~= "/" then d = "/"..d end
  if d:sub(-2,-1) ~= "/" then d = d.."/" end
  d = d:gsub("//","/")
  curdir = d
  curpath = curdrive.."://"..d
end

function term.setpath(p)
  if type(p) ~= "string" then return error("Path must be a string, provided: "..type(p)) end
  local dv, d = p:match("(.+)://(.+)")
  if (not dv) or (not d) then return error("Invalied path: "..p) end
  if not fs.drives()[dv] then return error("Drive '"..dv.."' doesn't exists !") end
  if d:sub(0,1) ~= "/" then d = "/"..d end
  if d:sub(-2,-1) ~= "/" then d = d.."/" end
  if not fs.exists(dv.."://"..d) then return error("Directory doesn't exists !") end
  if not fs.isDirectory(dv.."://"..d) then return error("It must be a directory, not a file") end
  d = d:gsub("//","/")
  curdrive, curdir, curpath = dv, d, dv.."://"..d
end

function term.getpath() return curpath end
function term.getdrive() return curdrive end
function term.getdirectory() return curdir end

function term.setPATH(p) PATH = p end
function term.getPATH() return PATH end

function term.parsePath(path)
  if path:sub(1,3) == "../" then
    local fld = {} --A list of folders in the path
    for p in string.gmatch(curdir,"(.-)/") do
      table.insert(fld,p)
    end
    if #fld == 0 then return curdrive..":///", fs.exists(curdrive..":///") end
    table.remove(fld, #fld) --Remove the last directory
    return curdrive..":///"..table.concat(fld,"/")..path:sub(4,-1), fs.exists(curdrive..":///"..table.concat(fld,"/")..path:sub(4,-1))
  elseif path:sub(1,2) == "./" then return curpath..sub(3,-1), fs.exists(curpath..sub(3,-1))
  elseif path == ".." then
    local fld = {} --A list of folders in the path
    for p in string.gmatch(curdir,"(.-)/") do
      table.insert(fld,p)
    end
    if #fld == 0 then return curdrive..":///", fs.exists(curdrive..":///") end
    table.remove(fld, #fld) --Remove the last directory
    return curdrive..":///"..table.concat(fld,"/"), fs.exists(curdrive..":///"..table.concat(fld,"/"))
  elseif path == "." then return curpath, fs.exists(curpath) end
  local d, p = path:match("(.+)://(.+)")
  if d and p then return path, fs.exists(path) end
  local d = path:match("(.+):") --ex: D:
  if d then return d..":///", fs.exists(d..":///") end
  local d = path:match("/(.+)")
  if d then return curdrive.."://"..path, fs.exists(curdrive.."://"..path) end
  return curpath..path, fs.exists(curpath..path)
end

function term.execute(command,...)
  if not command then return false, "No command" end
  if fs.exists(curpath..command..".lua") then
    local chunk, err = fs.load(curpath..command..".lua")
    if not chunk then color(8) print("\nL-ERR:"..tostring(err)) color(7) return false, tostring(err) end
    local ok, err = pcall(chunk,...)
    if not ok then color(8) print("ERR: "..tostring(err)) color(7) return false, tostring(err) end
    if not fs.exists(curpath) then curdir, curpath = "/", curdrive..":///" end
    color(8) pal() palt() cam() clip() return true
  end
  for path in nextPath(PATH) do
    if fs.exists(path) then
      local files = fs.directoryItems(path)
      for _,file in ipairs(files) do
        if file == command..".lua" then
          local chunk, err = fs.load(path..file)
          if not chunk then color(8) print("\nL-ERR:"..tostring(err)) color(7) return false, tostring(err) end
          local ok, err = pcall(chunk,...)
          if not ok then color(8) print("\nERR: "..tostring(err)) color(7) return false, tostring(err) end
          if not fs.exists(curpath) then curdir, curpath = "/", curdrive..":///" end
          color(7) pal() palt() cam() clip() return true
        end
      end
    end
  end
  color(9) print("File not found") color(7) return false, "File not found"
end

function term.loop() --Enter the while loop of the terminal
  cursor("none")
  clearEStack()
  color(13) checkCursor() print(term.getpath().."> ",false) color(7)
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
        color(13) checkCursor() print(term.getpath().."> ",false) blink = true cursor("none") color(7)
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
