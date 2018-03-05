--A group of tips to be displayed in the terminal as "Tip of the day:"

local tips = {}

for line in fs.lines("C:/Help/Tips") do
  table.insert(tips, line)
end

local config = ConfigUtils.get("TipOfTheDay")

config.pos = config.pos or 0
config.date = config.date or ""

if config.date ~= os.date("%Y%m%d",os.time()) then

  config.date = os.date("%Y%m%d",os.time())
  config.pos = (config.pos % #tips) + 1

  ConfigUtils.saveConfig()

end

local tip = tips[config.pos]
color(7) print("\nTip of the day:")
color(6) print(" "..tip.."\n")
