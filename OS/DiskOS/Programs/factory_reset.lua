if select(1,...) == "-?" then
  printUsage(
    "factory_reset","Reflashes DiskOS and Reboots"
  )
  return
end

local term = require("terminal")
fs.remove("C:/boot.lua")
for addr=0x15000, 0x17FFF do
  poke(addr,0x82)
end
flip()
sleep(1)
reboot()