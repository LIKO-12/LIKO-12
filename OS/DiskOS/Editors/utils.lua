--This file is reponsible for providing a base to create standalone mode editors.
--Like the paint and edit program.

local eapi = require("Editors")
local utils = {}

local swidth, sheight = screenSize()

function utils:newTool(readonly)
  local tool = {} --The tool editor api.
  
  tool.flavor = eapi.flavor
  tool.flavorBack = eapi.flavorBack
  tool.background = eapi.background
  
  local sid --Selected option id
  
  local controlID = 11 --The sprite id of the first control button icon.
  local controlNum = 3 --The number of the control buttons at the top right corner of the editor.
  local controlGrid = {swidth-8*controlNum,0, 8*controlNum,8, controlNum,1}
  
  function tool:drawTopBar()
    rect(0,0,swidth,8,false,self.flavor)
    SpriteGroup(55, 0,0, 4,1, 1,1, false, _SystemSheet) --The LIKO12 Logo
    SpriteGroup(controlID, controlGrid[1],controlGrid[2], controlGrid[5],controlGrid[6], 1,1, false, _SystemSheet)
    if readonly then
      _SystemSheet:draw(controlID-2, controlGrid[1]+8,controlGrid[2])
    end
    if sid then
      if readonly and sid == 1 then
        _SystemSheet:draw(controlID+24-2, controlGrid[1]+sid*8,controlGrid[2])
      else
        _SystemSheet:draw(controlID+24+sid, controlGrid[1]+sid*8,controlGrid[2])
      end
    end
  end
  
  function tool:drawBottomBar()
    rect(0,sheight-8,swidth,8,false,self.flavor)
  end
  
  function tool:drawUI()
    clear(self.background) --Clear the screen
    self:drawTopBar() --Draw the top bar
    self:drawBottomBar() --Draw the bottom bar
  end
  
  function tool:start(editor,reload,save,data,hotkey)
    self.editor = editor
    local screen = screenshot() --Backup the screen
    local px,py,pc = printCursor() --Backup the current printing cursor.
    cursor("normal") --Set the current cursor.
    
    if data then --Import some data.
      self.editor:import(data)
    end
    
    self.editor:entered() --Enter the editor.
    
    local eflag = false --Controls selection mode flag.
    local hflag = false --Mouse hover flag.
    
    --The control buttons actions
    local controls = {
      function() --Reload
        self.editor:leaved()
        if reload then reload(self) end
        self.editor:entered()
      end,

      function() --Save
        if readonly then
          _systemMessage("The file is readonly !",5,9,4)
        else
          if save then save(self) end
          _systemMessage("Saved successfully",1)
        end
      end,

      function() --Exit
        self.editor:leaved()
        return true
      end
    }
    
    for event, a,b,c,d,e,f in pullEvent do
      if event == "keypressed" then
        if a == "escape" then
          eflag = not eflag
          if eflag then
            cursor("none")
            sid = 1
          else
            cursor("normal")
            sid = false
          end
          pushMatrix() cam() self:drawTopBar() popMatrix()
        elseif eflag then
          if a == "left" then
            sid = sid - 1
            if sid < 0 then sid = 2 end
            pushMatrix() cam() self:drawTopBar() popMatrix()
          elseif a == "right" then
            sid = sid + 1
            if sid > 2 then sid = 0 end
            pushMatrix() cam() self:drawTopBar() popMatrix()
          elseif a == "return" then
            if controls[sid+1]() then break end
            sid, eflag = false, false
            pushMatrix() cam() self:drawTopBar() popMatrix()
          end
        else
          local key, sc = a, b
          if(isKDown("lalt", "ralt")) then
            key = "alt-" .. key
            sc = "alt-" .. sc
          end
          if(isKDown("lctrl", "rctrl", "lgui", "rgui", "capslock")) then
            key = "ctrl-" .. key
            sc = "ctrl-" .. sc
          end
          if(isKDown("lshift", "rshift")) then
            key = "shift-" .. key
            sc = "shift-" .. sc
          end
          
          local ishotkey --Was it an hotkey ?
          
          if key == "ctrl-s" then
            if controls[2]() then break end
            pushMatrix() cam() self:drawTopBar() popMatrix()
          elseif key == "ctrl-l" then
            if controls[1]() then break end
            pushMatrix() cam() self:drawTopBar() popMatrix()
          elseif key == "ctrl-q" then
            if controls[3]() then break end
            pushMatrix() cam() self:drawTopBar() popMatrix()
          elseif hotkey then
            if hotkey(self,key,sc) then
              ishotkey = true
            end
          end
          
          sc = "sc_"..sc
          
          if self.editor.keymap and not ishotkey then
            local usedKey
            if self.editor.keymap[key] then usedKey = key
            elseif self.editor.keymap[sc] then usedKey = sc
            end
            if usedKey then
              self.editor.keymap[usedKey](self.editor,c)
              self.editor.lastKey = usedKey
            end
          end
          if self.editor[event] and not ishotkey then self.editor[event](self.editor,a,b,c,d,e,f) end
        end
      elseif event == "mousepressed" and not eflag then
        local cx, cy = whereInGrid(a,b,controlGrid)
        if cx then
          cursor("handpress")
          hflag = "d"
          sid = cx-1
          pushMatrix() cam() self:drawTopBar() popMatrix()
        else
          if self.editor[event] then self.editor[event](self.editor,a,b,c,d,e,f) end
        end
      elseif event == "mousemoved" and not eflag then
        local cx, cy = whereInGrid(a,b,controlGrid)
        if cx then
          if hflag and hflag == "d" then
            sid = cx-1
            pushMatrix() cam() self:drawTopBar() popMatrix()
          elseif not hflag then
            cursor("handrelease")
            hflag = "h"
          end
        else
          if hflag and hflag == "h" then
            hflag = false
            cursor("normal")
          end
          if self.editor[event] then self.editor[event](self.editor,a,b,c,d,e,f) end
        end
      elseif event == "mousereleased" and not eflag then
        local cx, cy = whereInGrid(a,b,controlGrid)
        if cx then
          if hflag and hflag == "d" then
            cursor("handrelease")
            if controls[sid+1]() then break end
            sid, hflag = false, false
            pushMatrix() cam() self:drawTopBar() popMatrix()
          elseif not hflag then
            hflag = "h"
            cursor("handrelease")
          end
        else
          if hflag then
            if hflag == "d" then
              sid = false
              pushMatrix() cam() self:drawTopBar() popMatrix()
            end
            cursor("normal")
            hflag = nil
          end
          if self.editor[event] then self.editor[event](self.editor,a,b,c,d,e,f) end
        end
      elseif eflag then
        if event == "touchpressed" then textinput(true) end
      else
        if self.editor[event] then self.editor[event](self.editor,a,b,c,d,e,f) end
      end
    end
    
    clear() --Clear the screen
    screen:image():draw(0,0) --Restore the old frame
    printCursor(px,py,pc) --Restore the old print cursor
  end
  
  return tool
end

return utils