--SFX Editor

local sfxobj = require("Libraries.sfx") --The sfx object

local eapi = select(1,...) --The editors api

local sw, sh = screenSize() --The screensize
local volColors = {1,2,13,6,12,14,15,7}

local se = {} --sfx editor

local sfxSlots = 64 --The amount of sfx slots
local sfxNotes = 32 --The number of notes in each sfx

local defaultSpeed = 0.25 --The default speed
local speed = defaultSpeed --The current sfx speed

local selectedSlot = 0
local selectedWave = 0

local playingNote = -1

local pitchGrid = {0,9, sfxNotes*4,12*7, sfxNotes,12*7}
local volumeGrid = {0,sh-8-8*2-1, sfxNotes*4,8*2, sfxNotes,8}

--The SFXes datas.
local sfxdata = {}
for i=0,sfxSlots-1 do
  local sfx = sfxobj(sfxNotes, defaultSpeed)
  for i=0,sfxNotes-1 do
    sfx:setNote(i,1,1,0,0) --Octave 0 is hidden...
  end
  sfxdata[i] = sfx
end

local patternImage = imagedata("LK12;GPUIMG;2x6;770007700077;")
local pattern2Image = imagedata("LK12;GPUIMG;4x2;00070070;")

local selection = {0,31}

local history_size = 32
local history_index = 1
local history = {}
local touched_graphs = false

local function drawGraph()
  local x,y = pitchGrid[1], pitchGrid[2]-1
  local x2,y2 = volumeGrid[1], volumeGrid[2]
  local sfx = sfxdata[selectedSlot]
  
  --Pitch Rectangle
  rect(x,y,pitchGrid[3]+1,pitchGrid[4]+4,false,0)
  --Octave Lines
  local spacing = 12
  for i=1,7 do
    line(x-1,y + i*spacing+1,x + pitchGrid[3]+1,y + i*spacing+1, 1)
  end
  
  --Volume Rectangle
  rect(x2,y2-1,volumeGrid[3]+1,volumeGrid[4]+2,false,0)
  --Horizontal Box (Style)
  rect(x,y+pitchGrid[4]+4, pitchGrid[3]+1+1, y2-1-y-pitchGrid[4]-4, false, 9)
  patternFill(patternImage)
  rect(x,y+pitchGrid[4]+4, pitchGrid[3]+1+1, y2-1-y-pitchGrid[4]-4, false, 4)
  patternFill()
  --Vertical Line (Style)
  rect(x+pitchGrid[3]+1,8, 4,sh-16, false, 9)
  patternFill(pattern2Image)
  rect(x+pitchGrid[3]+1,8, 4,sh-16, false, 4)
  patternFill()
  
  local playingNote = math.floor(playingNote)
  
  -- Selection line
  if(selection[1] ~= 0 or selection[2] ~= 31)then
    rect(x+selection[1]*4+1,93,selection[2]*4 - selection[1]*4 + 2,3,false,2)
  end
  --Notes lines
  for i=0, sfxNotes-1 do
    local note,oct,wave,amp = sfx:getNote(i); note = note-1
    if wave >= 0 and amp > 0 then
      local line_col = 1
      if((i >= selection[1] and i <= selection[2]) and not (selection[1] == 0 and selection[2] == 31))then line_col = 2 end
      rect(x+1+i*4, y+12*8-(note+oct*12), 2, note+oct*12-9, false, (playingNote == i and 6 or line_col))
      rect(x+1+i*4, y+12*8-(note+oct*12), 2, 2, false, 8+wave)
    end
    
    local vol = math.floor(amp*7)
    
    if wave < 0 then vol = 0 end
    
    rect(x2+1+i*4, y2+(7-vol)*2, 3,2, false, volColors[vol+1])
  end
end

local slotLeft, slotLeftDown = {sw-26,15,4,7}, false
local slotRight, slotRightDown = {sw-9,15,4,7}, false

function se:drawSlot()
  color(12)
  print("SLOT:",sw-53,16)
  if slotLeftDown then pal(9,4) end
  _SystemSheet:draw(164,slotLeft[1],slotLeft[2])
  pal()
  
  color(13)
  rect(sw-21,15,fontWidth()*2+3,fontHeight()+1, false, 6)
  print(selectedSlot, sw-20,16, fontWidth()*2+2, "right")
  
  if slotRightDown then pal(9,4) end
  _SystemSheet:draw(165,slotRight[1],slotRight[2])
  pal()
end

local speedLeft, speedLeftDown = {sw-25,27,4,7}, false
local speedRight, speedRightDown = {sw-8,27,4,7}, false

function se:drawSpeed()
  color(7)
  print("SPEED:",sw-55,28)
  if speedLeftDown then pal(9,4) end
  _SystemSheet:draw(164,speedLeft[1],speedLeft[2])
  pal()
  
  color(13)
  rect(sw-20,27,fontWidth()*2+3,fontHeight()+1, false, 6)
  print(speed/0.25, sw-19,28, fontWidth()*2+2, "right")
  
  if speedRightDown then pal(9,4) end
  _SystemSheet:draw(165,speedRight[1],speedRight[2])
  pal()
end

local playRect, playDown = {sw-8,sh-8,8,8}, false

function se:drawPlay()
  if playingNote >= 0 then
    _SystemSheet:draw(playDown and 41 or 17,playRect[1],playRect[2])
  else
    _SystemSheet:draw(playDown and 40 or 16,playRect[1],playRect[2])
  end
end

local waveGrid,waveHover,waveDown = {sw-56,40,9*6,7,6,1}, false, false

function se:drawWave()
  rect(waveGrid[1],waveGrid[2],waveGrid[3],waveGrid[4], false, 5)
  for i=0,5 do
    local colorize = (waveHover and waveHover == i+1) or (selectedWave == i)
    local down = (waveDown and waveHover and waveHover == i+1) or (selectedWave == i)
    
    if colorize then pal(6,8+i) end
    if down then palt(13,true) end
    
    _SystemSheet:draw(173+i,down and waveGrid[1]+i*9+1 or waveGrid[1]+i*9,down and waveGrid[2]+1 or waveGrid[2])
    
    pal() palt()
  end
end

local SelectButtons = {
  ["x_origin"] = sw-55,
  ["y_origin"] = 52,
  ["sel_x_orig"] = sw-56,
  ["sel_y_orig"] = 60,
  ["sel_R_offset"] = 17,
  ["selB_offset"] = 33,
  ["sel_clear_offset"] = 23,
  ["selA_L_down"] = false,
  ["selA_R_down"] = false,
  ["sel_clr_down"] = false,
  ["selB_L_down"] = false,
  ["selB_R_down"] = false,
}

function se:drawSelect()
  local sb = SelectButtons
  local ix,iy = sb.x_origin,sb.y_origin
  local sx,sy = sb.sel_x_orig,sb.sel_y_orig
  color(7)
  print("Selection:",ix + 2,iy)
  
  --Selection Start Controls
  if sb.selA_L_down then pal(9,4) end
  _SystemSheet:draw(164,sx,sy)
  pal()
  
  color(13)
  rect(sx + 5,sy,fontWidth()*2+3,fontHeight()+1, false, 6)
  print(selection[1] + 1, sx+6, sy+1, fontWidth()*2+2, "right")
  
  if sb.selA_R_down then pal(9,4) end
  _SystemSheet:draw(165,sx + sb.sel_R_offset,sy)
  pal()
  
  -- Selection Clear Control
  local back_col = 9
  if(sb.sel_clr_down)then pal(7,13) back_col = 4 end
  rect(sx + sb.sel_clear_offset+1, sy+1, 6, 6, false, back_col)
  _SystemSheet:draw(120, sx + sb.sel_clear_offset, sy)
  pal()
  
  --Selection End Controls
  local sx = sx + sb.selB_offset
  if sb.selB_L_down then pal(9,4) end
  _SystemSheet:draw(164,sx,sy)
  pal()
  
  color(13)
  rect(sx + 5,sy,fontWidth()*2+3,fontHeight()+1, false, 6)
  print(selection[2] + 1, sx+6, sy+1, fontWidth()*2+2, "right")
  
  if sb.selB_R_down then pal(9,4) end
  _SystemSheet:draw(165,sx + 17,sy)
  pal()
end

local ToolButtons = {
  ["x_origin"] = sw-56,
  ["y_origin"] = 71,
  ["tools_offset"] = 6,
  ["tools_spacing"] = 11,
  ["tool_down"] = -1,
  ["waves_offset"] = 30,
  ["wave_down"] = -1,
  ["copy_buffer"] = nil,
}
function se:drawTools()
  local tb = ToolButtons
  color(7)
  print("Tools",tb.x_origin + 14,tb.y_origin)
  local box_col = 6
  for i=0,4 do
    for j=0,1 do
      local x_off = tb.x_origin + i * tb.tools_spacing
      local y_off = tb.y_origin + tb.tools_offset + j * tb.tools_spacing + 1
      if(tb.tool_down == i+j*5)then box_col = 1 end
      rect(x_off + 1, y_off + 1,9,9, false, 13)
      rect(x_off, y_off,9,9, false, box_col)
      box_col = 6
    end
  end
  pal(7,13)
  local ix,iy = tb.x_origin + 1, tb.y_origin + tb.tools_offset + 2
  _SystemSheet:draw(179, ix, iy)
  _SystemSheet:draw(180, ix + tb.tools_spacing, iy)
  --spr_clear:image():draw(ix + 22, iy)
  _SystemSheet:draw(82, ix + 21, iy -1)
  _SystemSheet:draw(83, ix + 32, iy -1)
  _SystemSheet:draw(84, ix + 44, iy -1)
  --Second Row
  for i=1,4 do
    _SystemSheet:draw(180 + i, ix + tb.tools_spacing * (i-1), iy + tb.tools_spacing)
  end
  _SystemSheet:draw(184, ix + tb.tools_spacing*4 + 7, iy + tb.tools_spacing + 8, math.pi)
  pal()
  
  for i=0,5 do
    if(tb.wave_down == i)then pal(6, 8+i) end
    _SystemSheet:draw(173 + i, tb.x_origin + i * 9, tb.y_origin + tb.waves_offset)
    pal()
  end
end

function se:entered()
  speed = sfxdata[selectedSlot]:getSpeed()
  -- Default state
  se:clearHistory()
  se:addHistory()
  
  eapi:drawUI()
  drawGraph()
  self:drawSlot()
  self:drawSpeed()
  self:drawPlay()
  self:drawWave()
  self:drawSelect()
  self:drawTools()
end

function se:leaved()
  --Stop the current playing SFX
  if Audio then Audio.stop() end
  playingNote = -1
end

local select_start = -1

function se:pitchMouse(state,x,y,button,istouch)
  local cx,cy = whereInGrid(x,y,pitchGrid)
  if cx and isMDown(1) then
    local sfx = sfxdata[selectedSlot]
    cx, cy = cx-1, 12*8-cy+1
    local note = cy%12
    local oct = math.floor(cy/12)
    local _,_,_,amp = sfx:getNote(cx)
    sfx:setNote(cx,note,oct,selectedWave,amp == 0 and 5/7 or amp)
    drawGraph()
  end
  if cx and isMDown(2) then
    if(state == "pressed")then
      select_start = cx-1
      selection[1] = select_start
      selection[2] = select_start
    elseif(select_start ~= -1)then
      if(cx > select_start)then
        selection[1] = select_start
        selection[2] = math.min(cx-1,31)
      else
        selection[1] = cx-1
        selection[2] = math.min(select_start,31)
      end
    end
    drawGraph()
    se:drawSelect()
  end
  if(state == "released")then select_start = -1 end
  
  if(not touched_graphs and cx and state == "moved" and (isMDown(1) or istouch))then
    touched_graphs = true
  end
end

function se:volumeMouse(state,x,y,button,istouch)
  local cx,cy = whereInGrid(x,y,volumeGrid)
  if cx and isMDown(1) then
    local sfx = sfxdata[selectedSlot]
    local note, oct, wave = sfx:getNote(cx-1)
    if wave < 0 and cy < 8 then wave = selectedWave end
    sfx:setNote(cx-1,false,false,wave,(8-cy)/7)
    drawGraph()
  end
  if(not touched_graphs and cx and state == "moved" and (isMDown(1) or istouch))then
    touched_graphs = true
  end
end

function se:slotMouse(state,x,y,button,istouch)
  if state == "pressed" then
    if isInRect(x,y,slotLeft) then
      slotLeftDown = true
      self:drawSlot()
    end
    
    if isInRect(x,y,slotRight) then
      slotRightDown = true
      self:drawSlot()
    end
  elseif state == "moved" then
    if not isInRect(x,y,slotLeft) and slotLeftDown then
      slotLeftDown = false
      self:drawSlot()
    end
    
    if not isInRect(x,y,slotRight) and slotRightDown then
      slotRightDown = false
      self:drawSlot()
    end
  else
    if isInRect(x,y,slotLeft) and slotLeftDown then
      selectedSlot = math.max(selectedSlot-1,0)
      speed = sfxdata[selectedSlot]:getSpeed()
    se:clearHistory()
    se:addHistory()
    end
    slotLeftDown = false
    
    if isInRect(x,y,slotRight) and slotRightDown then
      selectedSlot = math.min(selectedSlot+1,sfxSlots-1)
      speed = sfxdata[selectedSlot]:getSpeed()
    se:clearHistory()
    se:addHistory()
    end
    slotRightDown = false
    
    drawGraph() self:drawSlot() self:drawSpeed()
  end
end

function se:speedMouse(state,x,y,button,istouch)
  if state == "pressed" then
    if isInRect(x,y,speedLeft) then
      speedLeftDown = true
      self:drawSpeed()
    end
    
    if isInRect(x,y,speedRight) then
      speedRightDown = true
      self:drawSpeed()
    end
  elseif state == "moved" then
    if not isInRect(x,y,speedLeft) and speedLeftDown then
      speedLeftDown = false
      self:drawSpeed()
    end
    
    if not isInRect(x,y,speedRight) and speedRightDown then
      speedRightDown = false
      self:drawSpeed()
    end
  else
    if isInRect(x,y,speedLeft) and speedLeftDown then
      speed = math.max(speed-0.25,0.25)
      sfxdata[selectedSlot]:setSpeed(speed)
    end
    speedLeftDown = false
    
    if isInRect(x,y,speedRight) and speedRightDown then
      speed = math.min(speed+0.25,99*0.25)
      sfxdata[selectedSlot]:setSpeed(speed)
    end
    speedRightDown = false
    
    self:drawSpeed()
  end
end

function se:playMouse(state,x,y,button,istouch)
  if state == "pressed" then
    if isInRect(x,y,playRect) then
      playDown = true
      self:drawPlay()
    end
  elseif state == "moved" then
    if not isInRect(x,y,playRect) and playDown then
      playDown = false
      self:drawPlay()
    end
  elseif state == "released" then
    if isInRect(x,y,playRect) and playDown then
      playDown = false
      if playingNote >= 0 then
        if Audio then Audio.stop() end
        playingNote = -1
      else
        sfxdata[selectedSlot]:play(0)
        playingNote = 0
      end
      drawGraph()
      self:drawPlay()
    end
  end
end

function se:waveMouse(state,x,y,button,istouch)
  local cx,cy = whereInGrid(x,y,waveGrid)
  
  if state == "pressed" then
    if cx then
      waveHover = cx
      waveDown = true
      self:drawWave()
    end
  elseif state == "moved" then
    if (waveHover and cx and waveHover ~= cx) or not waveHover then
      waveHover = cx
      self:drawWave()
    elseif waveHover and not cx then
      waveHover = false
      waveDown = false
      self:drawWave()
    end
  elseif state == "released" then
    if waveDown and cx then
      selectedWave = cx-1
      self:drawWave()
    end
    waveDown = false
  end
end

function se:selectMouse(state,x,y,button,istouch)
  local sb = SelectButtons
  if state == "pressed" then
    -- Selection A Left
    if isInRect(x,y,{sb.sel_x_orig, sb.sel_y_orig, 4,7}) then
      if(selection[1] ~= 0)then selection[1] = selection[1] - 1 end
      sb.selA_L_down = true
      self:drawSelect()
    -- Selection A Right
    elseif isInRect(x,y,{sb.sel_x_orig + sb.sel_R_offset, sb.sel_y_orig, 4,7}) then
      if(selection[1] < 30 and selection[1] < selection[2])then selection[1] = selection[1] + 1 end
      sb.selA_R_down = true
      self:drawSelect()
    -- Selection Clear
    elseif isInRect(x,y,{sb.sel_x_orig + sb.sel_clear_offset, sb.sel_y_orig, 8, 8})then
      selection[1] = 0 selection[2] = 31
      sb.sel_clr_down = true
      self:drawSelect()
    -- Selection B Left
    elseif isInRect(x,y,{sb.sel_x_orig + sb.selB_offset, sb.sel_y_orig, 4,7}) then
      if(selection[2] ~= 1 and selection[2] > selection[1])then selection[2] = selection[2] - 1 end
      sb.selB_L_down = true
      self:drawSelect()
    -- Selection B Right
    elseif isInRect(x,y,{sb.sel_x_orig + sb.selB_offset + sb.sel_R_offset, sb.sel_y_orig, 4,7}) then
      if(selection[2] < 31)then selection[2] = selection[2] + 1 end
      sb.selB_R_down = true
      self:drawSelect()
    end
  elseif state == "released" then
    sb.selA_L_down = false
    sb.selA_R_down = false
    sb.selB_L_down = false
    sb.selB_R_down = false
    sb.sel_clr_down = false
    self:drawSelect()
  end
end

local tools_grid = {ToolButtons.x_origin, ToolButtons.y_origin + ToolButtons.tools_offset, 5*11,2*11, 5,2}
local waves_grid = {ToolButtons.x_origin, ToolButtons.y_origin + ToolButtons.waves_offset, 9*6,8,6,1}

function se:toolPitchUp()
  local sfx = sfxdata[selectedSlot]
  for i=selection[1],selection[2] do
    local note,oct,wave,amp = sfx:getNote(i)
    -- Make sure we're not at max
    if(oct <= 7 or note < 12)then
      -- loop
      if(note == 12)then
        note = 1
        oct = oct + 1
      else
        note = note + 1
      end
    end
    if(amp > 0)then 
      sfx:setNote(i,note,oct)
    end
  end
  drawGraph()
  se:addHistory()
end
function se:toolPitchDown()
  local sfx = sfxdata[selectedSlot]
  for i=selection[1],selection[2] do
    local note,oct,wave,amp = sfx:getNote(i)
    -- Make sure we're not at min
    if(oct > 1 or note > 1)then
      -- loop
      if(note == 1)then
        note = 12
        oct = oct - 1
      else
        note = note - 1
      end
    end
    sfx:setNote(i,note,oct)
  end
  drawGraph()
  se:addHistory()
end
function se:toolOctaveUp()
  local sfx = sfxdata[selectedSlot]
  for i=selection[1],selection[2] do
    local note,oct,wave,amp = sfx:getNote(i)
    if(oct <= 6)then
      oct = oct + 1
    end
    if(amp > 0)then
      sfx:setNote(i,note,oct)
    end
  end
  se:addHistory()
end
function se:toolOctaveDown()
  local sfx = sfxdata[selectedSlot]
  for i=selection[1],selection[2] do
    local note,oct = sfx:getNote(i)
    if(oct > 1)then
      oct = oct - 1
    end
    sfx:setNote(i,note,oct)
  end
  se:addHistory()
end

function se:toolCopy()
  local sfx = sfxobj(selection[2]+1 - selection[1]+1, sfxdata[selectedSlot]:getSpeed())
  local ind = 1
  for i=selection[1],math.min(sfxNotes-1,selection[2]) do
    local c_note,c_oct,c_wave,c_vol = sfxdata[selectedSlot]:getNote(i)
    sfx:setNote(ind,c_note,c_oct,c_wave,c_vol)
    ind = ind + 1
  end
  
  --Save to clipboard
  local copy = sfxdata[selectedSlot]:export():sub(3,-2):sub(selection[1]*6+1,(selection[2]+1)*6)
  
  clipboard(copy)
  color(4)
  _systemMessage("SFX data ["..(selection[1]+1).."-"..(selection[2]+1).."] copied to buffer")
  drawGraph()
end
function se:toolPaste()
  local paste = nil
  local clip = clipboard()
  
  local ok, err = pcall(function()
    if(clip:sub(-1,-1) ~= ",")then clip = clip.."," end
    local new_sfx = sfxobj(#clip/6,1)
    new_sfx:import("1:"..clip)
    paste = new_sfx
    
    local notes_given = paste.notes - 1
    local notes_pasted = math.min(selection[2] - selection[1],notes_given)
    local target_area = {selection[1], math.min(selection[2],selection[1] + notes_given)}
    local sfx = sfxdata[selectedSlot]
    local ind = 0
    for i = target_area[1],target_area[2] do
      local note,oct,wave,vol = paste:getNote(ind)
      sfx:setNote(i,note,oct,wave,vol)
      ind = ind + 1
    end
    
    selection[2] = math.min(target_area[2], selection[1] + notes_pasted)
    se:addHistory()
    _systemMessage("Pasted "..notes_pasted.." of "..notes_given.." notes to ["..(target_area[1]+1).."-"..(target_area[2]+1).."]")
  end)
  if not ok then
    _systemMessage("No SFX data in buffer to paste!",5)
    cprint("PASTE ERR: "..(err or "nil"))
  end
  drawGraph()
end
function se:toolDelete()
  -- Clear all notes in selection
  local sfx = sfxdata[selectedSlot]
  for i=selection[1],selection[2] do
    sfx:setNote(i,1,1,0,0)
  end
  drawGraph()
  se:addHistory()
end
function se:toolFlatten()
  local notes = {}
  local sfx = sfxdata[selectedSlot]
  for i=selection[1],selection[2] do
    local note, oct, _, amp = sfx:getNote(i)
    if(amp > 0)then
      table.insert(notes, oct * 12 + note)
    end
  end
  local sum = 0
  for i=1,#notes do
    sum = sum + notes[i]
  end
  local result = sum/#notes
  local average_note = {result % 12, math.floor(result/12)}
  for i=selection[1],selection[2] do
    local _,_,_,amp = sfx:getNote(i)
    if(amp > 0)then
      sfx:setNote(i, average_note[1], average_note[2])
    end
  end
  drawGraph()
  se:addHistory()
end
function se:toolUndo()
  if(history_index < history_size and history[history_index + 1] ~= nil)then
    sfxdata[selectedSlot]:import(history[history_index + 1])
    history_index = history_index + 1
  else
    _systemMessage("No more steps to undo available.")
  end
  drawGraph()
end
function se:toolRedo()
  if(history_index - 1 > 0)then
    sfxdata[selectedSlot]:import(history[history_index - 1])
    history_index = history_index - 1
  else
    _systemMessage("No more steps to redo available.")
  end
  drawGraph()
end

function se:toolsMouse(state,x,y,button,istouch)
  local cx,cy = whereInGrid(x,y, tools_grid)
  local tb = ToolButtons
  
  if(cx and state == "pressed")then
    local tools = {
      {se.toolPitchUp, se.toolPitchDown, se.toolCopy, se.toolPaste, se.toolDelete},
      {se.toolOctaveUp, se.toolOctaveDown, se.toolFlatten,se.toolUndo,se.toolRedo},
    }
    tb.tool_down = cx-1 + (cy-1)*5
    if(tools[cy][cx] ~= nil)then
      tools[cy][cx]()
    end
    self:drawTools()
  end
  if(state == "pressed")then
    cx,cy = whereInGrid(x,y,waves_grid)
    if(cx)then
      tb.wave_down = cx -1
      
      local sfx = sfxdata[selectedSlot]
      for i=selection[1],selection[2] do
        local note,oct,wave,amp = sfx:getNote(i)
        sfx:setNote(i,note,oct,cx-1,amp)
      end
      
      self:drawTools()
    end
  end
  if state == "released" then
    tb.tool_down = -1
    tb.wave_down = -1
    self:drawTools()
  end
end

function se:addHistory()
  if(history_index > 1)then
    for i = 1, history_index-1 do
      table.remove(history,1)
    end
    history_index = 1
  end
  table.insert(history, 1, sfxdata[selectedSlot]:export())
  if(#history > history_size)then table.remove(history, history_size+1) end
end
function se:clearHistory()
  history_index = 1
  history = {}
end

se.keymap = {
  --Play SFX
  ["space"] = function(self)
    if playingNote >= 0 then
      if Audio then Audio.stop() end
      playingNote = -1
    else
      sfxdata[selectedSlot]:play(0)
      playingNote = 0
    end
    drawGraph()
    self:drawPlay()
  end,
  
  --Select Waveform
  ["1"] = function(self)
    selectedWave = 0
    self:drawWave()
  end,
  
  ["2"] = function(self)
    selectedWave = 1
    self:drawWave()
  end,
  
  ["3"] = function(self)
    selectedWave = 2
    self:drawWave()
  end,
  
  ["4"] = function(self)
    selectedWave = 3
    self:drawWave()
  end,
  
  ["5"] = function(self)
    selectedWave = 4
    self:drawWave()
  end,
  
  ["6"] = function(self)
    selectedWave = 5
    self:drawWave()
  end,
  
  --Decrease speed
  ["z"] = function(self)
    speed = math.max(speed-0.25,0.25)
    sfxdata[selectedSlot]:setSpeed(speed)
    self:drawSpeed()
  end,
  
  --Increase speed
  ["x"] = function(self)
    speed = math.min(speed+0.25,99*0.25)
    sfxdata[selectedSlot]:setSpeed(speed)
    self:drawSpeed()
  end,
  
  --Decrease slot
  ["a"] = function(self)
    selectedSlot = math.max(selectedSlot-1,0)
    speed = sfxdata[selectedSlot]:getSpeed()
    drawGraph() self:drawSlot() self:drawSpeed()
  end,
  
  --Increase slot
  ["s"] = function(self)
    selectedSlot = math.min(selectedSlot+1,sfxSlots-1)
    speed = sfxdata[selectedSlot]:getSpeed()
    drawGraph() self:drawSlot() self:drawSpeed()
  end,
  
  ["f"] = se.toolFlatten,
  ["m"] = se.addHistory,
  ["n"] = se.clearHistory,
  
  ["up"] = se.toolPitchUp,
  ["down"] = se.toolPitchDown,
  ["left"] = function(self)
    if(selection[1] > 0)then
      selection[1] = selection[1] - 1
      selection[2] = selection[2] - 1
    end
    self:drawSelect()
    drawGraph()
  end,
  ["right"] = function(self)
    if(selection[2] < 31)then
      selection[1] = selection[1] + 1
      selection[2] = selection[2] + 1
    end
    self:drawSelect()
    drawGraph()
  end,
  
  ["ctrl-c"] = se.toolCopy,
  ["ctrl-v"] = se.toolPaste,
  ["delete"] = se.toolDelete,
  ["ctrl-z"] = se.toolUndo,
  ["ctrl-y"] = se.toolRedo,
}


function se:checkGraphs()
  if(touched_graphs)then
    se:addHistory()
    touched_graphs = false
  end
end

function se:update(dt)
  if playingNote >= 0 then
    playingNote = playingNote + (dt*sfxNotes)/speed
    if playingNote >= sfxNotes then
      playingNote = -1
      self:drawPlay()
    end
    drawGraph()
  end
end

function se:mousepressed(x,y,button,istouch)
  self:pitchMouse("pressed",x,y,button,istouch)
  self:volumeMouse("pressed",x,y,button,istouch)
  self:slotMouse("pressed",x,y,button,istouch)
  self:speedMouse("pressed",x,y,button,istouch)
  self:playMouse("pressed",x,y,button,istouch)
  self:waveMouse("pressed",x,y,button,istouch)
  self:selectMouse("pressed",x,y,button,istouch)
  self:toolsMouse("pressed",x,y,button,istouch)
end

function se:mousemoved(x,y,button,istouch)
  self:pitchMouse("moved",x,y,dx,dy,istouch)
  self:volumeMouse("moved",x,y,dx,dy,istouch)
  self:slotMouse("moved",x,y,dx,dy,istouch)
  self:speedMouse("moved",x,y,dx,dy,istouch)
  self:playMouse("moved",x,y,dx,dy,istouch)
  self:waveMouse("moved",x,y,dx,dy,istouch)
  self:toolsMouse("moved",x,y,dx,dy,istouch)
end

function se:mousereleased(x,y,button,istouch)
  self:pitchMouse("released",x,y,button,istouch)
  self:volumeMouse("released",x,y,button,istouch)
  self:slotMouse("released",x,y,button,istouch)
  self:speedMouse("released",x,y,button,istouch)
  self:playMouse("released",x,y,button,istouch)
  self:waveMouse("released",x,y,button,istouch)
  self:selectMouse("released",x,y,button,istouch)
  self:toolsMouse("released",x,y,button,istouch)
  self:checkGraphs()
end

function se:export()
  local data, dpos = {}, 1
  for i=0,sfxSlots-1 do
    data[dpos] = sfxdata[i]:export():sub(1,-2)
    data[dpos+1] = ";\n"
    dpos = dpos +2
  end
  return table.concat(data)
end

function se:import(data)
  data = data:gsub("\n","")
  local id = 0
  for sfxd in data:gmatch("(.-);") do
    sfxdata[id]:import(sfxd..",")
    id = id + 1
  end
end

function se:encode()
  local data, dpos = {}, 1
  for i=0,sfxSlots-1 do
    data[dpos] = sfxdata[i]:encode()
    dpos = dpos +1
  end
  
  return table.concat(data)
end

function se:decode(data)
  for i=0,sfxSlots-1 do
    local bin = data:sub(i*53+1,i*53+53+1)
    sfxdata[i]:decode(bin)
  end
end

return se