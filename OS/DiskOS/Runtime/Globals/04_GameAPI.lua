--Games special API loader

local Globals = (...) or {}

function Globals.___autoEventLoop()
  if _G._init and type(_G._init) == "function" then
    _G._init()
  end
  if type(_G._eventLoop) == "boolean" and not _G._eventLoop then return end --Skip the auto eventLoop.
  if _G._update or _G._draw or _G._eventLoop then
    eventLoop()
  end
end

setfenv(Globals.___autoEventLoop,Globals)

local json = require("Libraries/JSON")

local pkeys = {} --Pressed keys
local rkeys = {} --Repeated keys
local dkeys = {} --Down keys
local tbtn = {false,false,false,false,false,false,false} --Touch buttons
local gpads = {} --Gamepads

local defaultbmap = {
  {"left","right","up","down","z","x","c"}, --Player 1
  {"s","f","e","d","tab","q","w"} --Player 2
}

if not fs.exists("C:/keymap.json") then
  fs.write("C:/keymap.json",json:encode_pretty(defaultbmap))
end

do --So I can hide this part in ZeroBran studio
  local bmap = json:decode(fs.read("C:/keymap.json"))

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
  
  glob.__BTNUpdate = function(dt)
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

local helpersloader, err = fs.load("C:/Libraries/diskHelpers.lua")
if not helpersloader then error(err) end
setfenv(helpersloader,Globals) helpersloader()

return Globals