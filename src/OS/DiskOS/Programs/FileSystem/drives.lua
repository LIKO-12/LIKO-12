--Lists the available virtual drives
if (...) == "-?" then
  printUsage(
    "drives","Lists the available virtual drives"
  )
  return
end

local dr = fs.drives()
for drive, data in pairs(dr) do
  local percent = math.floor((((data.usage*100)/data.size)*100))/100
  
  color(12) print(drive,false)
  color(7) print(" - ",false)
  color(6) print(math.floor(data.usage/102.4)/10,false)
  color(7) print("/"..(math.floor(data.size/102.4)/10).." KB ",false)
  
  if data.Readonly then
    color(15) print("[Readonly]")
  else
    color(11-math.min(math.floor(percent/25),3))
    if drive == "C" then color(6) end --The usage of the C drive doesn't matter
    print("("..percent.."%)")
  end
end