if select(1,...) == "-?" then
  printUsage("version","Print the current version number.")
  return
end

color(11) print("LIKO-12 V".._LIKO_Version)
if old then
  color(6) print("Updated from: V".._LIKO_Old)
end
