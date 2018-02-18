--A shell with the ability to chain commands

local term = require("terminal")

local parser = require("Libraries/parser/parser")
parser:loadParser("xshell")

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
  ok = true
  flag = false
  result = parser:parseLines({args}, 0)
  parsed = result[1]
  for k, v in ipairs(parsed) do
    if k % 2 ~= 0 then
      if parsed[k] == "command" then
        if flag then
          if ok then
            ok = term.execute(unpack(split(parsed[k+1])))
          end
          flag = false
        else
          ok = term.execute(unpack(split(parsed[k+1])))
        end
      elseif parsed[k] == "chainer" then
      elseif parsed[k] == "conditionalChainer" then
        flag = true
      end
    end
  end
  --[[ flag = false
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
  term.execute(unpack(current)) ]]--
end
if #args < 1 then
  -- when interactively
  while true do
    color(7) print("> ",false)
    code = input(); print("")
    if not code or code == "exit" then break end
    execute(code)
  end
else execute(table.concat(args, " "))
end
