--This file is responsible about the editors shown after pressing escape--
local term = require("terminal")
local MainDrive = term.getMainDrive()

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

* editor.keymap = {} here you can assign your key binds:
editor.keymap["backspace"] = function(self,isrepeat) end
The key name can be any love2d key constant or and scancode
You can combine it with ctrl, alt or shift, ex: editor.keymap["ctrl-c"]

* Note when reading existing editors:
The may use some api functions defined at DiskOS/System/api.lua

Good luck !

==Contributers to this file==
(Add your name when contributing to this file)

- Rami Sabbagh (RamiLego4Game)
]]

local swidth, sheight = screenSize()

--WIP new editors system
function edit:initialize()
  self.flavor = 9 --Orange
  self.flavorBack = 4 --Brown
  self.background = 5 --Dark Grey
  
  self.editorsheet = SpriteSheet(image(fs.read(MainDrive..":/editorsheet.lk12")),24,16)
  
  self.active = 4 --Active editor
  
  self.editors = {"music","sfx","tile","sprite","code"; music=1,sfx=2,tile=3,sprite=4,code=5}
  self.saveid = {-1,"sfx","tilemap","spritesheet","luacode";sfx=2,tilemap=3,spritesheet=4,luacode=5}
  self.chunks = {} --Editors Code Chunks
  self.leditors = {} --Loaded editors (Executed chunks)
  
  self.icons = imagedata(5*8,2*8)
  self.icons:paste(self.editorsheet.img:data(),0,0, (24-#self.editors)*8,0, #self.editors*8,8)
  self.icons:paste(self.editorsheet.img:data(),0,8, (24-#self.editors)*8,0, #self.editors*8,8)
  self.icons:map(function(x,y,c)
    if y < 8 then if c == 0 then return self.flavor else return self.flavorBack end; else
    if c == 0 then return self.flavorBack else return self.flavor end; end
  end)
  self.icons = self.icons:image()
  
  self.iconsBGQuad = self.icons:quad(0,0,self.icons:width(),8)
  self.iconsQuads = {}
  for i=1,#self.editors do
    table.insert(self.iconsQuads,self.icons:quad(self.icons:width()-i*8,8, 8,8))
  end
  
  local editors = {"soon","sfx","tile","sprite","code","soon"} --List of built-in editors to create chunks of
  for k, v in ipairs(editors) do --Load chunks
    local chunk, err = fs.load(MainDrive..":/Editors/"..v..".lua")
    if not chunk then error(err or "Error loading: "..tostring(v)) end
    table.insert(self.chunks,k,chunk)
  end
  
  self:clearData()
  
  self.modeGrid = {swidth-(#self.editors*8),0,#self.editors*8,8,#self.editors,1} --The editor selection grid
  self.modeGridFlag = false
  self.modeGridHover = false
  self:loadCursors()
end

function edit:addEditor(code, name, saveid, icon)
  --Verification
  if type(code) ~= "string" and type(code) ~= "function" then return error("The editor code must be a string or a chunk, provided: "..type(code)) end
  if type(name) ~= "string" then return error("Editor name must be a string, provided: "..type(name)) end
  if type(saveid) ~= "number" and type(saveid) ~= "string" then return error("The saveid must be -1 or a string, provided: "..type(saveid)) end
  if type(saveid) == "number" and saveid ~= -1 then return error("The saveid can be -1 or a string, provided: "..saveid) end
  if type(icon) ~= "table" then return error("Icon must be provided, got "..type(icon).." instead") end
  if not (icon.typeOf and icon.type) then return error("Invalid Icon") end
  if icon:type() == "GPU.image" then icon = icon:data() end
  if icon:type() ~= "GPU.imageData" then return error("Icon must be a GPU image or imagedata !, provided: "..icon:type()) end
  
  --Chunk creation
  local chunk, err = code, "Unknown Error"
  if type(code) == "string" then
    chunk = false
    chunk, err = loadstring(code)
  end
  if not chunk then return error("Failed to load the chunk: "..tostring(err)) end
  
  --Execute the chunk
  local ok, editor = pcall(chunk,self)
  if not ok then return error("Failed to execute the chunk: "..tostring(editor)) end
  
  --Proccess the icon
  local bgicon = imagedata(8,8):paste(icon)
  local fgicon = imagedata(8,8):paste(icon)
  bgicon:map(function(x,y,c) if c == 0 then return self.flavor else return self.flavorBack end end)
  fgicon:map(function(x,y,c) if c == 0 then return self.flavorBack else return self.flavor end end)
  
  local newicons = imagedata(self.icons:width()+8,16)
  newicons:paste(self.icons:data(),8,0)
  newicons:paste(bgicon,0,0):paste(fgicon,0,8)
  
  self.icons = newicons:image()
  self.iconsBGQuad = self.icons:quad(0,0,self.icons:width(),8)
  for k,quad in ipairs(self.iconsQuads) do
    local oldx,oldy = quad:getViewport()
    self.iconsQuads[k] = self.icons:quad(oldx+8,oldy,8,8)
  end
  table.insert(self.iconsQuads,self.icons:quad(0,8,8,8))
  
  --Register the editor
  table.insert(self.editors,name)
  self.editors[name] = #self.editors
  table.insert(self.saveid,saveid)
  self.saveid[saveid] = #self.saveid
  table.insert(self.chunks,chunk)
  table.insert(self.leditors,editor)
  
  --Update the mode grid
  self.modeGrid = {swidth-(#self.editors*8),0,#self.editors*8,8,#self.editors,1}
end

function edit:clearData()
  --Will restart the editors simply
  self.leditors = {}
  for k,v in ipairs(self.chunks) do
    local editor = v(self)
    self.leditors[k] = editor
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
  
  self.icons:draw((swidth-#self.editors*8),0, 0, 1,1, self.iconsBGQuad)
  self.icons:draw(swidth-self.active*8,0, 0, 1,1, self.iconsQuads[self.active])
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

function edit:export() --Export editors data
  local edata = {}
  
  for k = #self.saveid, 1, -1 do
    local v = self.saveid[k]
    if v ~= -1 and self.leditors[k].export then
      
      local data = self.leditors[k]:export()
      if type(data) ~= "nil" then
        edata[v] = data
      end
      
    end
  end
  
  return edata
end

function edit:import(edata)
  for saveId, saveData in pairs(edata) do
    local editorId = self.saveid[saveId]
    if editorId and self.leditors[editorId].import then
      self.leditors[editorId]:import(saveData)
    end
  end
end

function edit:encode() --Encode editors data into binary
  local edata = {}
  
  for k = #self.saveid, 1, -1 do
    local v = self.saveid[k]
    if v ~= -1 and self.leditors[k].encode then
      
      local data = self.leditors[k]:encode()
      if type(data) ~= "nil" then
        edata[v] = data
      end
      
    end
  end
  
  return edata
end

function edit:decode(edata) --Decode editors data from binary
  for saveId, saveData in pairs(edata) do
    local editorId = self.saveid[saveId]
    if editorId and self.leditors[editorId].decode then
      self.leditors[editorId]:decode(saveData)
    end
  end
end

function edit:loop() --Starts the while loop
  cursor("normal")
  if self.leditors[self.active]["entered"] then self.leditors[self.active]:entered() end
  while true do
    local event, a, b, c, d, e, f = pullEvent()
    if event == "keypressed" then
      if a == "escape" then --Quit the loop and return to the terminal
        if self.leditors[self.active]["leaved"] then self.leditors[self.active]:leaved() end
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
        
        local term = require("terminal")
        local hotkey --Was it an hotkey ?
        
        pushMatrix() pushPalette() pushColor()
        if key == "ctrl-s" then
          local oldprint = print
          local err
          print = function(msg) if color() == 9 and not err then err = msg end end
          
          if not self.filePath then
            err = "Missing save name !"
          else
            local exitCode, exitErr = term.execute("save")
            
            if exitCode == 1 then
              err = "Failed: "..exitErr
            elseif exitCode == 2 or exitCode == 3 then
              err = "Failed, type save in terminal for info"
            elseif exitCode == 4 then
              err = "Save command not found !"
            end
          end
		  
          if err and err:len() > 4 then
            _systemMessage(err,5,9,4)
          else
            _systemMessage("Saved successfully",1)
          end
          print = oldprint
          hotkey = true
        elseif key == "ctrl-l" then
          local oldprint = print
          local err
          print = function(msg) if color() == 9 and not err then err = msg end end
          
          if not self.filePath then
            err = "Missing save name !"
          else
            term.execute("load")
          end
          
          if err and err:len() > 4 then
            _systemMessage(err,5,9,4)
          else
            _systemMessage("Reloaded successfully",1)
          end
          print = oldprint
          hotkey = true
        elseif key == "ctrl-r" then
          term.ecommand("run")
          if self.leditors[self.active]["leaved"] then self.leditors[self.active]:leaved() end
          hotkey = true
          break
        end
        popMatrix() popPalette() popColor()
        
        if key == "alt-left" then
          if self.active == #self.editors then
            self:switchEditor(1)
          else
            self:switchEditor(self.active+1)
          end
          hotkey = true
        elseif key == "alt-right" then
          if self.active == 1 then
            self:switchEditor(#self.editors)
          else
            self:switchEditor(self.active-1)
          end
          hotkey = true
        end
        
        if self.leditors[self.active].keymap and not hotkey then
          local usedKey
          if self.leditors[self.active].keymap[key] then usedKey = key
          elseif self.leditors[self.active].keymap["sc_"..sc] then usedKey = "sc_"..sc
          end
          if usedKey then
            self.leditors[self.active].keymap[usedKey](self.leditors[self.active], c)
            self.leditors[self.active].lastKey = usedKey
          end
        end
        if self.leditors[self.active][event] and not hotkey then self.leditors[self.active][event](self.leditors[self.active],a,b,c,d,e,f) end
      end
    elseif event == "mousepressed" then
      local cx, cy = whereInGrid(a,b, self.modeGrid)
      if cx then
        self.modeGridFlag = true
        cursor("handpress")
        self:switchEditor(#self.editors-cx+1)
      else
        if self.leditors[self.active][event] then self.leditors[self.active][event](self.leditors[self.active],a,b,c,d,e,f) end
      end
    elseif event == "mousemoved" then
      local cx, cy = whereInGrid(a,b, self.modeGrid)
      if cx then
        if self.modeGridFlag then
          self:switchEditor(#self.editors-cx+1)
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
          self:switchEditor(#self.editors-cx+1)
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
