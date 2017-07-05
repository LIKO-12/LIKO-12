local term = require("C://terminal")
fs.remove("C://boot.lua")
for addr=0x15000, 0x17FFF do
  poke(addr,0x82)
end
flip()
sleep(1)
reboot()