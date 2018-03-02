--A group of tips to be displayed in the terminal as "Tip of the day:"

local tips = {
  "You can view the system files by switching to drive C 'cd C:'",
  "You can factory_reset DiskOS by typing 'factory_reset'",
  "You can update old LIKO-12 games (older than V0.0.5A) by using the 'loadcart' command",
  "You can play piano notes by using the 'play' program",
  "You can check the drives usage by typing 'drives'",
  "You can check the available API functions by typing 'apis'",
  "You can store your own programs in D:/Programs/",
  "You can always look in other people's code to see how to use a feature",
  "There are included libraries for things ranging from collision detection to object orientation",
  "If you want code to run on boot up, place it in autoexec.lua in the D: drive.",
  "Updates overwrite the C: drive, so place your own data in the D: drive",
}

local seed = tonumber(os.date("%Y%m%d",os.time()))

local oldseed = math.randomseed()

math.randomseed(seed)
local tipid = math.random(1,#tips)
math.randomseed(oldseed)

local tip = tips[tipid]
color(7) print("\nTip of the day:")
color(6) print(" "..tip.."\n")
