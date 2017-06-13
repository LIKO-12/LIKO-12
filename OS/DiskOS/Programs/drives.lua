--Lists the available virtual drives
local dr = fs.drives()
for drive, data in pairs(dr) do
  print(drive.." - "..data.usage.."/"..data.size.." Byte ("..(math.floor((((data.usage*100)/data.size)*100))/100).."%)\n",false)
end