if select(1,...) == "-?" then
  printUsage(
    "install_demos","Installs some demo games"
  )
  return
end

fs.newDirectory("D://Demos/")
for k,v in ipairs(fs.directoryItems("C://Demos/")) do
  local data = fs.read("C://Demos/"..v)
  fs.write("D://Demos/"..v, data)
end
color(11) print("Installed to D://Demos/")