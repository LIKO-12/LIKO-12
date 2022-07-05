--[[
This file has been added by pull request #216

==Contributors to this file==
(Add your name when contributing to this file)
- Martin Aguilar (mrtnpwn)
]]

local args = {...}
local message = {}

if args[1] == '-?' or args[1] == nil or #args < 1 then
  printUsage('echo <message>', 'Print a message to stdout')
  return
end

for i, x in pairs(args) do
  table.insert(message, x)
end

local result = table.concat(message, ' ')

print(result)
