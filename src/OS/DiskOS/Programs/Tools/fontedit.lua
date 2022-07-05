--Font editor
local args = {...} --Get the arguments passed to this program
if #args < 1 or args[1] == "-?" then
  printUsage(
    "fontedit <file>","Create or edit an existing font file."
  )
  return
end

local term = require("terminal")

local filename = table.concat(args," ")
filename = term.resolve(filename)

cprint(filename)

if fs.exists(filename) then --Load the font.
  
else --Create a new font.
  color(9) print("Input character dimensions:")

  color(11) print("Width: ",false)
  color(7) local width = TextUtils.textInput()
  if not width or width:len() == 0 then print("") return end
  local w = tonumber(width)
  if not w then return 1, "\nInvalid Width: "..width..", width must be a number !" end
  w = math.floor(w)
  if w <= 0 then return 1, "\nInvalid Width: "..width..", width must be a positive integer!" end

  color(11) print(", Height: ",false)
  color(7) local height = TextUtils.textInput()
  if not height or height:len() == 0 then print("") return end
  local h = tonumber(height)
  if not h then return 1, "\nInvalid Height: "..height..", height must be a number !" end
  h = math.floor(h)
  if h <= 0 then return 1, "\nInvalid Height: "..height..", height must be a positive integer!" end
  
  print("")
end