local args = {...} --Get the arguments passed to this program
if tostring(args[1] or "soft") == "hard" then
  print("HARD REBOOTING ...") sleep(0.25)
  reboot(true)
else
  print("SOFT REBOOTING ...") sleep(0.25)
  reboot(false)
end