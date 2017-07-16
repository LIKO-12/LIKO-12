--This file is responsible about the editors shown after pressing escape--
local edit = {}

--=Contributing Guide=--
--[[
Creating an editor:
1. Create a new file at Editors folder
2. Make a new table at the top of the file and add it as an return value in the file ex: local ce = {}; return ce
3. Edit self.editors in edit:initialize and change the name of a slot to the name of .lua file of your editor (without adding the .lua)
4. Edit self.saveid in edit:initialize and change the value of a slot to a save id for your editor, leave -1 if it doesn't save.

* The editor api is passed as an argument to the editor file, to access it add this to the top of your file:
local eapi = select(1,...)

* The only usefull function in the editor api is eapi:drawUI()
which clears the whole screen and draws the top and bottom bars of every editor
Besure to call this at editor:entered()

* editor:entered() is called when the user switches to your editor
The first argument passed tk this callback is the previos editor table, be warned it could be a nil when yur editor is the first to be chosed !
The rest arguments are the return values of oldeditor:leaved()
Be sure to call eapi:drawUI() here to clear the screen

* editor:leaved() is called when the user is switching to an other editor than your
The first argument is the table of the new editor
You can return values that are passed to editor:entered() [see above]

* editor:export() is called when the editors are saving the data to a disk, you must 
pass a string of the editor data that may be loaded later at editor:import see down V

* editor:import(data) is called when the editors are loading from a disk, you will be passed the data string the editor passed in editor:export
it won't be called if there is no data to load.

* You don't have to do the while loop in your editor (see written editors)
The editor api automatically handles the pullEvent() for you
When an event happens editor:"event name" is called with the arguments of the event, ex:
function editor:mousepressed(x,y, button, is touch) end
function editor:update(dt) end

* editor.keymap = {} here you can assign you key binds:
editor.keymap["backspace"] = function(self,isrepeat) end
The key name can be any love2d key constant or and scancode
You can combine it with ctrl, alt or shift, ex: editor.keymap["ctrl-c"]

* Note when reading existing editors:
The may use some api functions defined at DiskOS/api.lua

Good luck !

==Contributers to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

local swidth, sheight = screenSize()

function edit:initialize()
  self.flavor = 9 --Orange
  self.flavorBack = 4 --Brown
  self.background = 5 --Dark Grey
  
  self.editorsheet = SpriteSheet(image(fs.read("C://editorsheet.lk12")),24,16)

  self.active = 3
  self.editors = {"soon","code","sprite","tile","soon","soon"}
  self.saveid =  {-1 , "luacode", "spritesheet", "tilemap", -1, -1}
  self.chunks = {}
  self.leditors = {}

  for k,v in ipairs(self.editors) do
    local chunk, err = fs.load("C://Editors/"..v..".lua")
    if not chunk then error(err or "Error loading: "..tostring(v)) end
    table.insert(self.chunks,k,chunk)
  end

  for k,v in ipairs(self.chunks) do
    table.insert(self.leditors,k,v(self))
  end

  self.modeGrid = {swidth-(#self.editors*8),0,#self.editors*8,8,#self.editors,1} --The editor selection grid
  self.modeGridFlag = false
  self.modeGridHover = false
  self:loadCursors()
end

function edit:clearData()
  --Will restart the editors simply
  self.leditors = {}
  for k,v in ipairs(self.chunks) do
    table.insert(self.leditors,k,v(self))
  end
end

function edit:loadCursors()
  pushPalette()
  palt()
  cursor(self.editorsheet:extract(1),"normal",1,1)
  cursor(self.editorsheet:extract(2),"handrelease",2,1)
  cursor(self.editorsheet:extract(3),"handpress",2,1)
  cursor(self.editorsheet:extract(4),"hand",4,4)
  cursor(self.editorsheet:extract(5),"cross",3,3)
  cursor(self.editorsheet:extract(7),"point",1,1)
  cursor(self.editorsheet:extract(8),"draw",3,3)
  
  cursor(self.editorsheet:extract(32),"normal_white",1,1)
  
  cursor(self.editorsheet:extract(149),"pencil",0,7)
  cursor(self.editorsheet:extract(150),"bucket",0,7)
  cursor(self.editorsheet:extract(151),"eraser",0,7)
  cursor(self.editorsheet:extract(152),"picker",0,7)
  popPalette()
end

function edit:drawBottomBar()
  rect(0,sheight-8,swidth,8,false,self.flavor)
end

function edit:drawTopBar()
  rect(0,0,swidth,8,false,self.flavor)
  SpriteGroup(55, 0,0, 4,1, 1,1, false, self.editorsheet) --The LIKO12 Logo
  SpriteGroup(24-#self.editors+1, (swidth-#self.editors*8), 0, #self.editors,1, 1,1, false, self.editorsheet) --The programs selection
  self.editorsheet:draw(48-(#self.editors-self.active),swidth-(#self.editors-self.active+1)*8,0) --The current selected program
end

function edit:drawUI()
  clear(self.background) --Clear the screen
  self:drawTopBar() --Draw the top bar
  self:drawBottomBar() --Draw the bottom bar
end

function edit:switchEditor(neweditor)
  if neweditor ~= self.active and self.leditors[neweditor] then
    local oldeditor = self.active; self.active = neweditor
    
    if self.leditors[neweditor].entered then
      if self.leditors[oldeditor].leaved then
        self.leditors[neweditor]:entered(self.leditors[oldeditor],self.leditors[oldeditor]:leaved(self.leditors[neweditor]))
      else
        self.leditors[neweditor]:entered(self.leditors[oldeditor])
      end
    else
      if self.leditors[oldeditor].leaved then
        self.leditors[oldeditor]:leaved(self.leditors[neweditor])
      end
    end
  end
end

function edit:import(data) --Import editors data
  data = data:gsub("\r\n","\n")
  local savePos = {}
  for k,v in ipairs(self.saveid) do
    if v ~= -1 and self.leditors[k].import then
      local dstart, dend = string.find(data,"___"..tostring(v).."___")
      if dstart then
        dstart = dend+2
        local dend, nextstart = string.find(data,"___",dstart)
        if dend then
          dend = dend-2
        else
          dend = -2 --The end of the file ignoring the last new line
        end
        local save = string.sub(data,dstart,dend)
        self.leditors[k]:import(save)
      end
    end
  end
end

function edit:export() --Export editors data
  local save = ""
  for k,v in ipairs(self.saveid) do
    if v ~= -1 and self.leditors[k].export then
      local data = self.leditors[k]:export()
      if type(data) ~= "nil" then
        --code = code.."\n['"..tostring(v).."'] = "..string.format("%q",data)..","
        save = save.."___"..tostring(v).."___\n"..data:gsub("___","").."\n"
      end
    end
  end
  return save
end

function edit:loop() --Starts the while loop
  cursor("normal")
  if edit.leditors[edit.active]["entered"] then edit.leditors[edit.active]:entered() end
  while true do
    local event, a, b, c, d, e, f = pullEvent()
    if event == "keypressed" then
      if a == "escape" then --Quit the loop and return to the terminal
        if edit.leditors[edit.active]["leaved"] then edit.leditors[edit.active]:leaved() end
        break
      else
        local key, sc = a, b
        if(isKDown("lalt", "ralt")) then
          key = "alt-" .. key
          sc = "alt-" .. sc
        end
        if(isKDown("lctrl", "rctrl")) then
          key = "ctrl-" .. key
          sc = "ctrl-" .. sc
        end
        if(isKDown("lshift", "rshift")) then
          key = "shift-" .. key
          sc = "shift-" .. sc
        end
        
        local term = require("C://terminal")
        
        pushMatrix() pushPalette() pushColor()
        if key == "ctrl-s" then
          local oldprint = print
          print = function() end
          term.execute("save")
          print = oldprint
        elseif key == "ctrl-l" then
          local oldprint = print
          print = function() end
          term.execute("load")
          print = oldprint
        elseif key == "ctrl-r" then
          local sbk = screenshot()
          local px,py,pc = printCursor()
          cam()
          term.execute("run")
          cam()
          printCursor(px,py,pc)
          sbk:image():draw(0,0)
        end
        popMatrix() popPalette() popColor()
        
        if key == "alt-right" then
          if self.active == #self.editors then
            self:switchEditor(1)
          else
            self:switchEditor(self.active+1)
          end
        elseif key == "alt-left" then
          if self.active == 1 then
            self:switchEditor(#self.editors)
          else
            self:switchEditor(self.active-1)
          end
        end
        
        if self.leditors[self.active].keymap then
          local usedKey
          if self.leditors[self.active].keymap[key] then usedKey = key
          elseif self.leditors[self.active].keymap[sc] then usedKey = sc
          end
          if usedKey then
            self.leditors[self.active].keymap[usedKey](self.leditors[self.active], c)
            self.leditors[self.active].lastKey = usedKey
          end
        end
        if self.leditors[self.active][event] then self.leditors[self.active][event](self.leditors[self.active],a,b,c,d,e,f) end
      end
    elseif event == "mousepressed" then
      local cx, cy = whereInGrid(a,b, self.modeGrid)
      if cx then
        self.modeGridFlag = true
        cursor("handpress")
        self:switchEditor(cx)
      else
        if self.leditors[self.active][event] then self.leditors[self.active][event](self.leditors[self.active],a,b,c,d,e,f) end
      end
    elseif event == "mousemoved" then
      local cx, cy = whereInGrid(a,b, self.modeGrid)
      if cx then
        if self.modeGridFlag then
          self:switchEditor(cx)
        else
          self.modeGridHover = true
          cursor("handrelease")
        end
      elseif not self.modeGridFlag then
        if self.modeGridHover then
          cursor("normal")
          self.modeGridHover = false
        end
        if self.leditors[self.active][event] then self.leditors[self.active][event](self.leditors[self.active],a,b,c,d,e,f) end
      else
        cursor("handpress")
      end
    elseif event == "mousereleased" then
      local cx, cy = whereInGrid(a,b, self.modeGrid)
      if cx then
        if self.modeGridFlag then
          self.modeGridHover = true
          self.modeGridFlag = false
          cursor("handrelease")
          self:switchEditor(cx)
        end
      else
        if self.modeGridFlag then
          self.modeGridHover = true
          self.modeGridFlag = false
          cursor("normal")
        end
        if self.leditors[self.active][event] then self.leditors[self.active][event](self.leditors[self.active],a,b,c,d,e,f) end
      end
    else
      if self.leditors[self.active][event] then self.leditors[self.active][event](self.leditors[self.active],a,b,c,d,e,f) end
    end
  end
end

edit:initialize()

return edit
