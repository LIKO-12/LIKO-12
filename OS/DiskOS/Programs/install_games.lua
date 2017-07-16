if select(1,...) == "-?" then
  printUsage(
    "install_game","Installs some built-in games"
  )
  return
end

fs.newDirectory("D://Games/")
for k,v in ipairs(fs.directoryItems("C://Games/")) do
  local data = fs.read("C://Games/"..v)
  fs.write("D://Games/"..v, data)
end
color(11) print("Installed to D://Games/")