--A group of tips to be displayed in the terminal as "Tip of the day:"

local function split(str)
  local t = {}
  for val in str:gmatch("[^\r\n]+") do
    table.insert(t, val)
  end
  return t
end

local tips = split(fs.read("C:/Help/Tips"))

local seed = tonumber(os.date("%Y%m%d",os.time()))

local oldseed = math.randomseed()

math.randomseed(seed)
local tipid = math.random(1,#tips)
math.randomseed(oldseed)

local tip = tips[tipid]
color(7) print("\nTip of the day:")
color(6) print(" "..tip.."\n")
