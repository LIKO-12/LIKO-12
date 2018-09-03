if select(1,...) == "-?" then
  printUsage(
    "factory_reset","Reflashes DiskOS and Reboots",
    "factory_reset -wipe","Wipes the C drive, reflashes DiskOS and reboots"
  )
  return
end
 fs.delete("C:/boot.lua")
 if select(1,...) == "-wipe" then
  local term = require("C:/terminal.lua")
  term.execute("rm","C:/")

  clear(0)
else
  local img = imagedata(screenSize())
  img:map(function(x,y,c)
    if x%2 == 0 then
      return 8
    else
      return 2
    end
  end)
  img:image():draw(0,0)
end
 flip()
sleep(1)
reboot()
