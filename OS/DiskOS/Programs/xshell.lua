--A shell with the ability to chain commands and a custom prompt

local version = "1.0.0"

local term = require("terminal")

local parser = require("Libraries/parser/parser")
parser:loadParser("xshell")

local args = {...}

local env = {}

env["PROMPT"] = ">"

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
  code = 0
  flag = false
  result = parser:parseLines({args}, 0)
  parsed = result[1]
  for k, v in ipairs(parsed) do
    if k % 2 ~= 0 then
      if parsed[k] == "command" then
        if flag then
          if code == 0 then
            code = term.execute(unpack(split(parsed[k+1])))
          end
          flag = false
        else
          code = term.execute(unpack(split(parsed[k+1])))
        end
      elseif parsed[k] == "chainer" then
      elseif parsed[k] == "conditionalChainer" then
        flag = true
      elseif parsed[k] == "assigner" then
        text = parsed[k+1]:sub(2)
        splitter = text:find("=")
        env[text:sub(1,splitter-1)] = text:sub(splitter+1)
      end
    end
  end
end

if args[1] == "-?" then
  printUsage(
    "xshell <text>", "run command in non interactive shell",
    "xshell", "Enter interactive shell",
    "xshell -v", "Prints current version of xshell"
  )
  return
elseif args[1] == "-v" then
  print(version)
elseif #args < 1 then
  -- when interactively
  while true do
    color(7) print(env["PROMPT"].." ",false)
    code = input(); print("")
    if not code or code == "exit" then break end
    execute(code)
  end
else execute(table.concat(args, " "))
end
