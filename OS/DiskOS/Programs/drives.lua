--Lists the available virtual drives
if select(1,...) == "-?" then
  printUsage(
    "drives","Lists the available virtual drives"
  )
  return
end

local dr = fs.drives()
for drive, data in pairs(dr) do
  print(drive.." - "..data.usage.."/"..data.size.." Byte ("..(math.floor((((data.usage*100)/data.size)*100))/100).."%)")
end