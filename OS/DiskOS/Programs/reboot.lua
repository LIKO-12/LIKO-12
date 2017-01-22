local args = {...} --Get the arguments passed to this program
if tostring(args[1] or "soft") == "hard" then
  print("\nHARD REBOOTING ...") sleep(0.25)
  reboot(true)
else
  print("\nSOFT REBOOTING ...") sleep(0.25)
  reboot(false)
end