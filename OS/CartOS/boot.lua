--assert(coroutine.yield("GPU:printCursor",2,2))
--assert(coroutine.yield("GPU:color",9))
--assert(coroutine.yield("GPU:print","LIKO-12 V0.6.0"))
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

--DebugDraw start--
--[[GPU.points(1,1, 192,1, 192,128, 1,128, 8)
GPU.points(0,1, 193,1, 193,128, 0,128, 3)
GPU.points(1,0, 192,0, 192,129, 1,129, 3)
GPU.rect(2,2, 190,126, true, 12)
GPU.line(2,2,191,2,191,127,2,127,2,2,12)
GPU.line(2,2, 191,127, 9)
GPU.line(191, 2,2,127, 9)
GPU.rect(10,42,10,10,false,9)
GPU.rect(10,30,10,10,false,9)
GPU.rect(10,30,10,10,true,8)
GPU.points(10,10, 10,19, 19,19, 19,10, 8)]]
--DebugDraw end--

GPU.printCursor(1,1)
GPU.color(9)
GPU.print("LIKO-12 V0.6.0")
GPU.flip()
CPU.sleep(1)
GPU.color(10)
GPU.print("Available Peripherals:")
GPU.color(8)
CPU.sleep(0.25)
for per,_ in pairs(perlist) do
  CPU.sleep(0.25)
  GPU.print(per)
end
GPU.flip()

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