require("love.thread")

local to_channel = love.thread.getChannel("To_WebThread")
local from_channel = love.thread.getChannel("From_WebThread")

local request = require("Engine.luajit-request")
if not ok then return end
local json = require("Engine.JSON")

while true do
  local req = to_channel:demand()
  if type(req) == "table" then
    local url = req[1]
    local args = json:decode(req[2])
    local out, errorcode, errorstr, errline = request.send(url,args)
    from_channel:push(json:encode({ url, out, errorcode, errorstr, errline }))
  end
end