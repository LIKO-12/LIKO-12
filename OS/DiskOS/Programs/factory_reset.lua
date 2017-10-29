if select(1,...) == "-?" then
  printUsage(
    "factory_reset","Reflashes DiskOS and Reboots"
  )
  return
end

fs.remove("C:/boot.lua")
for addr=0x0, 0x14FFF do
  poke(addr,0x82)
end
flip()
sleep(1)
reboot()