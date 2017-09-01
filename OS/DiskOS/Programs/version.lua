if select(1,...) == "-?" then
  printUsage("version","Print the current version number.")
  return
end

local _, new, old = coroutine.yield("BIOS:GetVersion")

color(11) print("LIKO-12 V"..new)
if old then
  color(6) print("Updated from: V"..old)
end
