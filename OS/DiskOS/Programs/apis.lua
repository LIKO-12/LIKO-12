if select(1,...) == "-?" then
  printUsage(
    "apis","Prints the available peripherals functions",
    "apis <peripheral>","Prints the functions of a specific peripheral"
  )
  return
end

--Print the list of functions for a peripheral, or all peripherals
local _,perlist = coroutine.yield("BIOS:listPeripherals")

palt(0,false) --Make black opaque

local peri = select(1,...)

local function waitkey()
  while true do
    local name, a = pullEvent()
    if name == "keypressed" then
      return false
    elseif name == "textinput" then
      if string.lower(a) == "q" then return true else return end
    elseif name == "touchpressed" then
      textinput(true)
    end
  end
end

local tw, th = termSize()
local sw, sh = screenSize()
local msg = "[press any key to continue, q to quit]"
local msglen = msg:len()

local function sprint(text)
  local cx, cy = printCursor()
  if cy < th-2 then print(text.." ",false) return end
  local tlen = text:len()+1
  if cx+tlen+1 >= tw then
    print("") pushColor() color(9)
    print(msg,false) popColor()
    flip()
    local quit = waitkey()
    printCursor(1,th)
    rect(0,sh-9,sw,8,false,0)
    if quit then return true end
    screenshot():image():draw(0,-8)
    printCursor(cx, th-3)
    print(text.." ",false) return
  else
    print(text.." ",false) return
  end
end

if peri then
 if not perlist[peri] then
   color(8) print("Peripheral '"..peri.."' doesn't exists") return
 end
 color(11) if sprint(peri..":") then return end color(7)
 for k, name in pairs(perlist[peri]) do
   if sprint(name) then return end
 end
else
 for per, funcs in pairs(perlist) do
   color(11) print("---"..per.."---") color(7)
   for k, name in pairs(funcs) do
     if sprint(name) then return end
   end
   print("") print("")
 end
end