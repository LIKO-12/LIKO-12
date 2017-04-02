--Text editor--
print("")
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(9) print("Must provide the path to the file") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
tar = term.parsePath(tar)

if fs.isDirectory(tar) then color(9) print("Can't edit directories !") return end
local eapi = require("C://Editors")
local edit = {}
edit.editorsheet = eapi.editorsheet
edit.flavor = eapi.flavor
edit.flavorBack = eapi.flavorBack
edit.background = eapi.background

local swidth, sheight = screenSize()

local sid --Selected option id

function edit:drawBottomBar()
  rect(1,sheight-7,swidth,8,false,self.flavor)
end

local controlID = 11
local controlNum = 3 --The number of the control buttons at the top right corner of the editor.
local controlGrid = {swidth-8*controlNum+1,1, 8*controlNum,8, controlNum,1}

function edit:drawTopBar()
  rect(1,1,swidth,8,false,self.flavor)
  SpriteGroup(55, 1,1, 4,1, 1,1, false, self.editorsheet) --The LIKO12 Logo
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
if fs.exists(tar) then texteditor:import(fs.read(tar)) end
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
      edit:drawTopBar()
    elseif eflag then
      if a == "left" then
        sid = sid - 1
        if sid < 0 then sid = 2 end
        edit:drawTopBar()
      elseif a == "right" then
        sid = sid + 1
        if sid > 2 then sid = 0 end
        edit:drawTopBar()
      elseif a == "return" then
        if controls[sid+1]() then break end
        sid, eflag = false, false
        edit:drawTopBar()
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
      
      if texteditor.keymap and texteditor.keymap[key] then texteditor.keymap[key](texteditor,c)
      elseif texteditor.keymap and texteditor.keymap[sc] then texteditor.keymap[sc](texteditor,c) end
      if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
    end
  elseif event == "mousepressed" and not eflag then
    local cx, cy = whereInGrid(a,b,controlGrid)
    if cx then
      cursor("handpress")
      hflag = "d"
      sid = cx-1
      edit:drawTopBar()
    else
      if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
    end
  elseif event == "mousemoved" and not eflag then
    local cx, cy = whereInGrid(a,b,controlGrid)
    if cx then
      if hflag and hflag == "d" then
        sid = cx-1
        edit:drawTopBar()
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
        edit:drawTopBar()
      elseif not hflag then
        hflag = "h"
        cursor("handrelease")
      end
    else
      if hflag then
        if hflag == "d" then
          sid = false
          edit:drawTopBar()
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

clear(1)
screen:image():draw(1,1)
printCursor(px,py,pc)