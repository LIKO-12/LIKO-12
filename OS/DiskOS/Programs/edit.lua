--Text editor--
local args = {...} --Get the arguments passed to this program
if #args < 1 or args[1] == "-?" then
  printUsage(
    "edit <file>","Open in the file editor"
  )
  return
end

local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
tar = term.resolve(tar)

if fs.exists(tar) and fs.isDirectory(tar) then color(8) print("Can't edit directories !") return end
local eapi = require("C://Editors")
local edit = {}
edit.editorsheet = eapi.editorsheet
edit.flavor = eapi.flavor
edit.flavorBack = eapi.flavorBack
edit.background = eapi.background

local swidth, sheight = screenSize()

local sid --Selected option id

function edit:drawBottomBar()
  rect(0,sheight-8,swidth,8,false,self.flavor)
end

local controlID = 11
local controlNum = 3 --The number of the control buttons at the top right corner of the editor.
local controlGrid = {swidth-8*controlNum,0, 8*controlNum,8, controlNum,1}

function edit:drawTopBar()
  rect(0,0,swidth,8,false,self.flavor)
  SpriteGroup(55, 0,0, 4,1, 1,1, false, self.editorsheet) --The LIKO12 Logo
  SpriteGroup(controlID, controlGrid[1],controlGrid[2], controlGrid[5],controlGrid[6], 1,1, false, self.editorsheet)
  if sid then
    SpriteGroup(controlID+24+sid, controlGrid[1]+sid*8,controlGrid[2], 1,1, 1,1, false, self.editorsheet)
  end
end

function edit:drawUI()
  clear(self.background) --Clear the screen
  self:drawTopBar() --Draw the top bar
  self:drawBottomBar() --Draw the bottom bar
end

local ok, texteditor = assert(pcall(assert(fs.load("C://Editors/code.lua")),edit))
if tar:sub(-4,-1) ~= ".lua" then texteditor.colorize = false end

local screen = screenshot()
local px,py,pc = printCursor()
cursor("normal")
if fs.exists(tar) then texteditor:import(fs.read(tar):gsub("\r\n","\n")) end
texteditor:entered()

local eflag = false
local hflag = false --hover flag

local controls = {
  function() --Reload
    texteditor:leaved()
    if fs.exists(tar) then texteditor:import(fs.read(tar)) end
    texteditor:entered()
  end,

  function() --Save
    local data = texteditor:export()
    fs.write(tar,data)
  end,

  function() --Exit
    texteditor:leaved()
    return true
  end
}

for event, a,b,c,d,e,f in pullEvent do
  if event == "keypressed" then
    if a == "escape" then
      --[[texteditor:leaved()
      break]]
      eflag = not eflag
      if eflag then
        cursor("none")
        sid = 1
      else
        cursor("normal")
        sid = false
      end
      pushMatrix() cam() edit:drawTopBar() popMatrix()
    elseif eflag then
      if a == "left" then
        sid = sid - 1
        if sid < 0 then sid = 2 end
        pushMatrix() cam() edit:drawTopBar() popMatrix()
      elseif a == "right" then
        sid = sid + 1
        if sid > 2 then sid = 0 end
        pushMatrix() cam() edit:drawTopBar() popMatrix()
      elseif a == "return" then
        if controls[sid+1]() then break end
        sid, eflag = false, false
        pushMatrix() cam() edit:drawTopBar() popMatrix()
      end
    else
      local key, sc = a, b
      if(isKDown("lalt", "ralt")) then
        key = "alt-" .. key
        sc = "alt-" .. sc
      end
      if(isKDown("lctrl", "rctrl", "capslock")) then
        key = "ctrl-" .. key
        sc = "ctrl-" .. sc
      end
      if(isKDown("lshift", "rshift")) then
        key = "shift-" .. key
        sc = "shift-" .. sc
      end

      if texteditor.keymap then
        local usedKey
        if texteditor.keymap[key] then usedKey = key
        elseif texteditor.keymap[sc] then usedKey = sc
        end
        if usedKey then
          texteditor.keymap[usedKey](texteditor,c)
          texteditor.lastKey = usedKey
        end
      end
      if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
    end
  elseif event == "mousepressed" and not eflag then
    local cx, cy = whereInGrid(a,b,controlGrid)
    if cx then
      cursor("handpress")
      hflag = "d"
      sid = cx-1
      pushMatrix() cam() edit:drawTopBar() popMatrix()
    else
      if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
    end
  elseif event == "mousemoved" and not eflag then
    local cx, cy = whereInGrid(a,b,controlGrid)
    if cx then
      if hflag and hflag == "d" then
        sid = cx-1
        pushMatrix() cam() edit:drawTopBar() popMatrix()
      elseif not hflag then
        cursor("handrelease")
        hflag = "h"
      end
    else
      if hflag and hflag == "h" then
        hflag = false
        cursor("normal")
      end
      if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
    end
  elseif event == "mousereleased" and not eflag then
    local cx, cy = whereInGrid(a,b,controlGrid)
    if cx then
      if hflag and hflag == "d" then
        cursor("handrelease")
        if controls[sid+1]() then break end
        sid, hflag = false, false
        pushMatrix() cam() edit:drawTopBar() popMatrix()
      elseif not hflag then
        hflag = "h"
        cursor("handrelease")
      end
    else
      if hflag then
        if hflag == "d" then
          sid = false
          pushMatrix() cam() edit:drawTopBar() popMatrix()
        end
        cursor("normal")
        hflag = nil
      end
      if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
    end
  elseif eflag then
    if event == "touchpressed" then textinput(true) end
  else
    if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
  end
end

clear()
screen:image():draw(0,0)
printCursor(px,py,pc)
