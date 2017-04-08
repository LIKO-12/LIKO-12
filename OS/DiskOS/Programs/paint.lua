--Paint Program--
print("")
local args = {...}
if #args < 1 then color(9) print("Must provide the path to the file") return end
local tar = table.concat(args," ")..".lk12" --The path may include whitespaces
local term = require("C://terminal")
tar = term.parsePath(tar)

if fs.exists(tar) and fs.isDirectory(tar) then color(9) print("Can't edit directories !") return end

local img, imgdata

if not fs.exists(tar) then --Create a new image
  color(10) print("Input image size:")
  
  color(12) print("Width: ",false)
  color(8) local width = input()
  if not width or width:len() == 0 then print("") return end
  local w = tonumber(width)
  if not w then color(9) print("\nInvalid Width: "..width..", width must be a number !") return end
  
  color(12) print(", Height: ",false)
  color(8) local height = input()
  if not height or height:len() == 0 then print("") return end
  local h = tonumber(height)
  if not h then color(9) print("\nInvalid Height: "..height..", height must be a number !") return end
  color(9) print("\nW:"..w.." H:"..h)
  
  imgdata = imagedata(w,h)
  img = imgdata:image()
else --Load the image
  local data = fs.read(tar)
  local ok, err = pcall(image,data)
  if not ok then color(9) print(err) return end
  img = err
  imgdata = img:data()
end

local eapi = require("C://Editors")
local edit = {}
edit.editorsheet = eapi.editorsheet
edit.flavor = eapi.flavor
edit.flavorBack = eapi.flavorBack
edit.background = 0

local swidth, sheight = screenSize()

local bgsprite = eapi.editorsheet:extract(59):image()
local bgquad = bgsprite:quad(1,1,swidth,sheight-8*2)

local sid --Selected option id

function edit:drawBottomBar()
  rect(1,sheight-7,swidth,8,false,self.flavor)
end

local controlID = 11
local controlNum = 3 --The number of the control buttons at the top right corner of the editor.
local controlGrid = {swidth-8*controlNum+1,1, 8*controlNum,8, controlNum,1}

function edit:drawTopBar()
  palt(1,true)
  rect(1,1,swidth,8,false,self.flavor)
  SpriteGroup(55, 1,1, 4,1, 1,1, false, self.editorsheet) --The LIKO12 Logo
  SpriteGroup(controlID, controlGrid[1],controlGrid[2], controlGrid[5],controlGrid[6], 1,1, false, self.editorsheet)
  if sid then
    SpriteGroup(controlID+24+sid, controlGrid[1]+sid*8,controlGrid[2], 1,1, 1,1, false, self.editorsheet)
  end
  palt(1,false)
end

function edit:drawBackground()
  rect(1,9,swidth,sheight-8*2,false,1)
  bgsprite:draw(1,9,0,1,1,bgquad)
end

function edit:drawUI()
  self:drawBackground()
  self:drawTopBar() --Draw the top bar
  self:drawBottomBar() --Draw the bottom bar
end

local screen = screenshot()
local px,py,pc = printCursor()
local ok, painteditor = assert(pcall(assert(fs.load("C://Editors/paint.lua")),edit,img,imgdata))

cursor("normal")
painteditor:entered()

local eflag = false
local hflag = false --hover flag

local controls = {
  function() --Reload
    painteditor:leaved()
    if fs.exists(tar) then
      local data = fs.read(tar)
      local ok, err = pcall(image,data)
      if not ok then color(9) print(err) return end
      img = err
      imgdata = img:data()
      painteditor:import(img,imgdata)
    end
    painteditor:entered()
  end,
  
  function() --Save
    local data = painteditor:export()
    fs.write(tar,data)
  end,
  
  function() --Exit
    painteditor:leaved()
    return true
  end 
}

for event, a,b,c,d,e,f in pullEvent do
  if event == "keypressed" then
    if a == "escape" then
      --[[painteditor:leaved()
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
      
      if painteditor.keymap and painteditor.keymap[key] then painteditor.keymap[key](painteditor,c)
      elseif painteditor.keymap and painteditor.keymap[sc] then painteditor.keymap[sc](painteditor,c) end
      if painteditor[event] then painteditor[event](painteditor,a,b,c,d,e,f) end
    end
  elseif event == "mousepressed" and not eflag then
    local cx, cy = whereInGrid(a,b,controlGrid)
    if cx then
      cursor("handpress")
      hflag = "d"
      sid = cx-1
      pushMatrix() cam() edit:drawTopBar() popMatrix()
    else
      if painteditor[event] then painteditor[event](painteditor,a,b,c,d,e,f) end
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
      if painteditor[event] then painteditor[event](painteditor,a,b,c,d,e,f) end
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
      if painteditor[event] then painteditor[event](painteditor,a,b,c,d,e,f) end
    end
  elseif eflag then
    if event == "touchpressed" then textinput(true) end
  else
    if painteditor[event] then painteditor[event](painteditor,a,b,c,d,e,f) end
  end
end

clear(1)
screen:image():draw(1,1)
printCursor(px,py,pc)