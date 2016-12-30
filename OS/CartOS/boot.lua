assert(coroutine.yield("GPU:printCursor",2,2))
assert(coroutine.yield("GPU:color",9))
assert(coroutine.yield("GPU:print","LIKO-12 V0.6.0"))
--assert(coroutine.yield("GPU:print","CartOS V0.0"))

--Building the api--
local _,perlist = coroutine.yield("BIOS:listPeripherals")
for peripheral,funcs in pairs(perlist) do
  _G[peripheral] = {}
  for _,func in ipairs(funcs) do
    local command = peripheral..":"..func
    _G[peripheral][func] = function(...)
      local args = {coroutine.yield(command,...)}
      if not args[1] then return error(args[2]) end
      local nargs = {}
      for k,v in ipairs(args) do
        if k >1 then table.insert(nargs,k-1,v) end
      end
      return unpack(nargs)
    end
  end
end
GPU.color(10)
GPU.print("Loaded the API")

local mflag = false
while true do
  local event, a, b, c, d, e = CPU.pullEvent()
  if event == "mousepressed" then
    mflag = true
  elseif event == "mousemoved" then
    if mflag then
      math.randomseed(os.clock()*os.time()*a*b)
      GPU.color(math.floor(math.random(9,16)))
      GPU.point(a,b)
    end
  elseif event == "mousereleased" then
    mflag = false
  end
end