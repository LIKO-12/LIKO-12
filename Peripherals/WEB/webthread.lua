local args = {}
require("love.thread")

local to_channel = select(1,...)
local from_channel = select(2,...)

local request = require("Engine.luajit-request")
local json = require("Engine.JSON")

while true do
  local req = to_channel:demand()
  if type(req) == "table" then
    local url = req[1]
    local args = json:decode(req[2])
    local out, errorcode, errorstr, errline = request.send(url,args)
    from_channel:push(json:encode({ url, out, errorcode, errorstr, errline }))
  elseif type(req) == "string" then
    if req == "shutdown" then
      break --Job done.
    end
  end
end