--A group of tips to be displayed in the terminal as "Tip of the day:"

local function split(str)
  local t = {}
  for val in str:gmatch("[^\r\n]+") do
    table.insert(t, val)
  end
  return t
end

local tips = split(fs.read("C:/Help/Tips"))

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
