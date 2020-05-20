--Games special API loader

local Globals = (...) or {}

local sw,sh = screenSize()

function Globals.pause()
  if Globals._DISABLE_PAUSE then return end
  
  pushMatrix()
  pushPalette()
  pushColor()
  
  palt() pal() colorPalette() cam()
  
  local oldClip = clip()
  
  local bkimg = screenshot():image()
  local scimg = screenshot(sw/8,sh/8, sw*0.75,sh*0.75)
  ImageUtils.darken(scimg,2)
  scimg = scimg:image()
  
  palt(0,false)
  scimg:draw(sw/8,sh/8)
  rect(sw/8,sh/8,sw*0.75,sh*0.75, true, 0) --Black
  rect(sw/8+1,sh/8+1,sw*0.75-2,sh*0.75-2, true, 7) --White
  rect(sw/8+2,sh/8+2,sw*0.75-4,sh*0.75-4, true, 0) --Black
  
  color(7)
  
  print("GAME IS PAUSED",0,sh*0.4, sw, "center")
  print("Press escape/return to resume",sw*0.175,sh*0.6, sw*0.65, "center")
  
  clearEStack()
  
  for event, a,b,c,d,e,f in pullEvent do
    if event == "keypressed" then
      if a == "escape" or a == "return" then
        break
      end
    end
  end
  
  bkimg:draw(0,0)
  
  if oldClip then clip(unpack(oldClip)) end
  
  popColor()
  popPalette()
  popMatrix()
end

local pkeys = {} --Pressed keys
local rkeys = {} --Repeated keys
local dkeys = {} --Down keys
local tbtn = {false,false,false,false,false,false,false} --Touch buttons
local gpads = {} --Gamepads

local defaultbmap = {
  {"left","right","up","down","z","x","c"}, --Player 1
  {"s","f","e","d","tab","q","w"} --Player 2
}

local mobilebnames = {
  "Left","Right","Up","Down","Green button","Red button","Blue button"
}

do --So I can hide this part in ZeroBran studio
  local bmap = ConfigUtils and ConfigUtils.get("GamesKeymap") or {}

  if not bmap[1] then
    bmap[1] = {defaultbmap[1][1], defaultbmap[1][2], defaultbmap[1][3], defaultbmap[1][4], defaultbmap[1][5], defaultbmap[1][6], defaultbmap[1][7]}
    if ConfigUtils then ConfigUtils.saveConfig() end
  end
  if not bmap[2] then
    bmap[2] = {defaultbmap[2][1], defaultbmap[2][2], defaultbmap[2][3], defaultbmap[2][4], defaultbmap[2][5], defaultbmap[2][6], defaultbmap[2][7]}
    if ConfigUtils then ConfigUtils.saveConfig() end
  end
  
  function Globals.getBtnName(n,p)
    local p = p or 1
    if type(n) ~= "number" then return error("Button id must be a number, provided: "..type(n)) end
    if type(p) ~= "number" then return error("Player id must be a number or nil, provided: "..type(p)) end
    n, p = math.floor(n), math.floor(p)
    if p < 1  then return error("The Player id is negative ("..p..") it must be positive !") end
    if n < 1 or n > 7 then return error("The Button id is out of range ("..n..") must be [1,7]") end
    
    if isMobile() and p == 1 then
      return mobilebnames[n]
    else
      local map = bmap[p]
      local bname = map[n]
      return string.upper(string.sub(bname,1,1))..string.sub(bname,2,-1)
    end
  end


  function Globals.btn(n,p)
    local p = p or 1
    if type(n) ~= "number" then return error("Button id must be a number, provided: "..type(n)) end
    if type(p) ~= "number" then return error("Player id must be a number or nil, provided: "..type(p)) end
    n, p = math.floor(n), math.floor(p)
    if p < 1  then return error("The Player id is negative ("..p..") it must be positive !") end
    if n < 1 or n > 7 then return error("The Button id is out of range ("..n..") must be [1,7]") end

    local map = bmap[p]
    local gmap = gpads[p]
    if not (map or gmap) then return false end --Failed to find a controller

    return dkeys[map[n]] or (p == 1 and tbtn[n]) or (gmap and gmap[n])
  end

  function Globals.btnp(n,p)
    local p = p or 1
    if type(n) ~= "number" then return error("Button id must be a number, provided: "..type(n)) end
    if type(p) ~= "number" then return error("Player id must be a number or nil, provided: "..type(p)) end
    n, p = math.floor(n), math.floor(p)
    if p < 1  then return error("The Player id is negative ("..p..") it must be positive !") end
    if n < 1 or n > 7 then return error("The Button id is out of range ("..n..") must be [1,7]") end

    local map = bmap[p]
    local gmap = gpads[p]
    if not (map or gmap) then return false end --Failed to find a controller

    if rkeys[map[n]] or (p == 1 and tbtn[n] and tbtn[n] >= 1) or (gmap and gmap[n] and gmap[n] >= 1) then
      return true, true
    else
      return pkeys[map[n]] or (p == 1 and tbtn[n] and tbtn[n] == 0) or (gmap and gmap[n] and gmap[n] == 0)
    end
  end

  Globals.__BTNUpdate = function(dt)
    pkeys = {} --Reset the table (easiest way)
    rkeys = {} --Reset the table (easiest way)
    for k,v in pairs(dkeys) do
      if not isKDown(k) then
        dkeys[k] = nil
      end
    end

    for k,v in ipairs(tbtn) do
      if v then
        if tbtn[k] >= 1 then
          tbtn[k] = 0.9
        end
        tbtn[k] = tbtn[k] + dt
      end
    end

    for id, gpad in pairs(gpads) do
      for k,v in ipairs(gpad) do
        if v then
          if gpad[k] >= 1 then
            gpad[k] = 0.9
          end
          gpad[k] = gpad[k] + dt
        end
      end
    end
  end

  Globals.__BTNKeypressed = function(a,b)
    pkeys[a] = true
    rkeys[a] = b
    dkeys[a] = true
  end

  Globals.__BTNTouchControl = function(state,n)
    if state then
      tbtn[n] = 0
    else
      tbtn[n] = false
    end
  end

  Globals.__BTNGamepad = function(state,n,id)
    if not gpads[id] then gpads[id] = {false,false,false,false,false,false} end
    if state then
      gpads[id][n] = 0
    else
      gpads[id][n] = false
    end
  end
end

--Persistent data API
local GameSaveID
local GameSaveData
local GameSaveSize = 1024*2 --2KB

if not fs.exists(_SystemDrive..":/GamesData") and not _GameDiskOS then fs.newDirectory(_SystemDrive..":/GamesData") end

function Globals.SaveID(name)
  if type(name) ~= "string" then return error("SaveID should be a string, provided: "..type(name)) end
  
  if GameSaveID then return error("SaveID could be only set once !") end
  
  GameSaveID, GameSaveData = name, ""
  
  if fs.exists(_SystemDrive..":/GamesData/"..GameSaveID..".bin") and not _GameDiskOS then
    GameSaveData = fs.read(_SystemDrive..":/GamesData/"..GameSaveID..".bin", GameSaveSize)
  end
end

function Globals.SaveData(data)
  if type(data) ~= "string" then return error("Save data should be a string, provided: "..type(data)) end
  
  if #data > GameSaveSize then return error("Save data can be 2KB maximum !") end
  
  if not GameSaveID then return error("Set SaveID inorder to save data !") end
  
  GameSaveData = data
  
  --Write the game data
  if _GameDiskOS then fs.write(string.format(_SystemDrive..":/GamesData/%s.bin",GameSaveID), GameSaveData) end
end

function Globals.LoadData()
  if not GameSaveID then return error("Set SaveID inorder to load data !") end
  
  return GameSaveData
end

--Helpers
local helpersloader, err = fs.load(_SystemDrive..":/Libraries/diskHelpers.lua")
if not helpersloader then error(err) end
setfenv(helpersloader,Globals) helpersloader()

return Globals