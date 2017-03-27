--Text editor--
print("")
local args = {...} --Get the arguments passed to this program
if #args < 1 then color(9) print("Must provide the path to the file") return end
local tar = table.concat(args," ") --The path may include whitespaces
local term = require("C://terminal")
tar = term.parsePath(tar)

if not fs.exists(tar) then color(9) print("File doesn't exists !") return end
if fs.isDirectory(tar) then color(9) print("Can't edit directories !") return end
local eapi = require("C://Editors")
local edit = {}
edit.editorsheet = eapi.editorsheet
edit.flavor = eapi.flavor
edit.flavorBack = eapi.flavorBack
edit.background = eapi.background

local swidth, sheight = screenSize()

function edit:drawBottomBar()
  rect(1,sheight-7,swidth,8,false,self.flavor)
end

function edit:drawTopBar()
  rect(1,1,swidth,8,false,self.flavor)
  SpriteGroup(55, 1,1, 4,1, 1,1, false, self.editorsheet) --The LIKO12 Logo
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
for event, a,b,c,d,e,f in pullEvent do
  if event == "keypressed" then
    if a == "escape" then
      texteditor:leaved()
      break
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
  else
    if texteditor[event] then texteditor[event](texteditor,a,b,c,d,e,f) end
  end
end

clear(1)
screen:image():draw(1,1)
printCursor(px,py,pc)