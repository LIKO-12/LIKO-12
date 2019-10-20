if (...) == "-?" then
  printUsage(
    "keymap","Remaps the controls keys"
  )
  return
end

color(9) print("(esc): set to default\n(enter): leave unchanged") color(7)

local defaultbmap = {
  {"left","right","up","down","z","x","c"}, --Player 1
  {"s","f","e","d","tab","q","w"} --Player 2
}

local bmap = ConfigUtils.get("GamesKeymap")

if not bmap[1] then
  bmap[1] = {unpack(defaultbmap[1])}
  ConfigUtils.saveConfig()
end
if not bmap[2] then
  bmap[2] = {unpack(defaultbmap[2])}
  ConfigUtils.saveConfig()
end

local bname = {"Left","Right","Up","Down","A","B","Start"}

local function getKey()
  local keysflag = {}
  for event,a,b,c in pullEvent do
    if event == "keypressed" then
      keysflag[a] = not c
    elseif event == "keyreleased" then
      if keysflag[a] then return a end
    end
  end
end

local function erase(str)
  for i=1, str:len() do
    printBackspace()
  end
end

for p=1, 2 do
  for b=1,#bname do
    if p == 1 then color(12) else color(8) end
    print("Player #"..p,false) color(6)
    print(" "..bname[b]..": ",false) color(7) print(bmap[p][b],false)
    local key = getKey()
    if key == "escape" then
      erase(bmap[p][b])
      if bmap[p][b] ~= defaultbmap[p][b] then color(9) end
      bmap[p][b] = defaultbmap[p][b]
      print(bmap[p][b],false)
    elseif key ~= "return" then
      erase(bmap[p][b])
      if bmap[p][b] ~= key then color(9) end
      bmap[p][b] = key
      print(bmap[p][b],false)
    end
    print("")
  end
end
color(9) print("Would you like to save the new configuration ? (y/n)",false)
while true do
  local answer = getKey()
  if answer == "y" then
    ConfigUtils.saveConfig()
    color(11) print(" Saved")
    break
  elseif answer == "n" then
    color(8) print(" Canceled")
    break
  end
end