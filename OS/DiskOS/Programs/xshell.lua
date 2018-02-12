--A shell with the ability to chain commands

local term = require("terminal")

local args = {...}

local function test(current, flag, result)
  if current ~= nil then
    if flag then
      if result then
        return true
      else return false
      end
    else return true
    end
  else
    return false
  end
end

local function split(str)
  local t = {}
  for val in str:gmatch("%S+") do
    table.insert(t, val)
  end
  return t
end

local function execute(args)
  flag = false
  result = true
  current = nil
  for i = 0, #args, 1
  do
    if args[i] and args[i] ~= " " then
      if args[i] == ";" then
        --do the next command uncondtionally
        if test(current, flag, result) then
          result = term.execute(unpack(current))
          current = {}
        end
      elseif args[i] == '&' then
        --do only if the command last was successful
        if test() then
          result = term.execute(unpack(current))
          current = {}
          flag = true
        end
      else
        if current then
          current[#current + 1] = args[i]
        else
          current = {args[i]}
        end
      end
    end
  end
  term.execute(unpack(current))
end

if #args < 1 then
  -- when interactively
  while true do
    color(7) print("> ",false)
    code = input(); print("")
    if not code or code == "exit" then break end
    execute(split(code))
  end
else execute(args)
end
