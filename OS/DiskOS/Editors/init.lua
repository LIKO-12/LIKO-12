--This file is responsible about the editors shown after pressing escape--
local edit = {}

local swidth, sheight = screenSize()

function edit:initialize()
  self.flavor = 10 --Orange
  self.flavorBack = 5 --Brown
  self.background = 6 --Dark Grey

  self.editorsheet = SpriteSheet(image(fs.read("C://editorsheet.lk12")),24,12)

  self.active = 3
  self.editors = {"sprite","sprite","sprite","sprite","sprite","sprite"}
  self.chunks = {}
  self.leditors = {}

  for k,v in ipairs(self.editors) do
    table.insert(self.chunks,k,fs.load("C://editors/"..v..".lua"))
  end

  for k,v in ipairs(self.chunks) do
    table.insert(self.leditors,k,v(self))
  end

  self.modeGrid = {swidth-(#self.editors*8)+1,1,#self.editors*8,8,#self.editors,1} --The editor selection grid
  self.modeGridFlag = false
  self.modeGridHover = false
  self:loadCursors()
end

function edit:loadCursors()
  cursor(self.editorsheet:extract(1),"normal",2,2)
  cursor(self.editorsheet:extract(2),"handrelease",3,2)
  cursor(self.editorsheet:extract(3),"handpress",3,2)
  cursor(self.editorsheet:extract(4),"hand",5,5)
  cursor(self.editorsheet:extract(5),"cross",4,4)
  cursor(self.editorsheet:extract(7),"point",2,2)
end

function edit:drawUI()
  clear(self.background) --Clear the screen
  rect(1,1,swidth,8,false,self.flavor) --Draw the top bar
  rect(1,sheight-7,swidth,8,false,self.flavor) --Draw the bottom bar
  
  SpriteGroup(55, 1,1, 4,1, 1,1, self.editorsheet) --The LIKO12 Logo
  SpriteGroup(24-#self.editors+1, (swidth-#self.editors*8) +1,1, #self.editors,1, 1,1, self.editorsheet) --The programs selection
  self.editorsheet:draw(48-(#self.editors-self.active),swidth-(#self.editors-self.active+1)*8+1,1) --The current selected program
end

function edit:switchEditor(neweditor)
  if neweditor ~= self.active and self.leditors[neweditor] then
    local oldeditor = self.active; self.active = neweditor
    if self.leditors[oldeditor].leaved then
      self.leditors[oldeditor]:leaved(self.leditors[neweditor])
    end
    
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

function edit:loop() --Starts the while loop
  cursor("normal")
  if edit.leditors[edit.active]["entered"] then edit.leditors[edit.active]:entered() end
  while true do
    local event, a, b, c, d, e, f = pullEvent()
    if event == "keypressed" then
      if a == "escape" then --Quit the loop and return to the terminal
        if edit.leditors[edit.active]["entered"] then edit.leditors[edit.active]:entered() end
        break
      else
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

return edit