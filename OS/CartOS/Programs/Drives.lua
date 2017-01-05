local dr = fs.drives() error(#dr)
for drive, data in pairs(dr) do
  print("\n"..drive.." - "..data.usage.."/"..data.size)
end