--Text editor--
print("")
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(9) print("Must provide the path to the file") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
tar = term.parsePath(tar)

if not fs.exists(tar) then fs.write(tar,"") end
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

function edit:drawTopBar()
  rect(1,1,swidth,8,false,self.flavor)
  SpriteGroup(55, 1,1, 4,1, 1,1, false, self.editorsheet) --The LIKO12 Logo
  SpriteGroup(11, swidth-8*3+1,1, 3,1, 1,1, false, self.editorsheet)
  if sid then
    SpriteGroup(35+sid, swidth-(2-sid+1)*8+1,1, 1,1, 1,1, false, self.editorsheet)
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
texteditor:import(fs.read(tar))
texteditor:entered()

local eflag = false

for event, a,b,c,d,e,f in pullEvent do
  if event == "keypressed" then
    if a == "escape" then
      --[[texteditor:leaved()
      break]]
      eflag = not eflag
      if eflag then sid = 1 else sid = false end
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
        if sid == 0 then --Reload
          texteditor:leaved()
          texteditor:import(fs.read(tar))
          texteditor:entered()
        elseif sid == 1 then --Save
          local data = texteditor:export()
          fs.write(tar,data)
        elseif sid == 2 then --Exit
          texteditor:leaved()
          break
        end
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
  elseif eflag then
    if event == "touchpressed" then textinput(true) end
  else
    if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
  end
end

clear(1)
screen:image():draw(1,1)
printCursor(px,py,pc)