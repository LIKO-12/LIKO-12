--List the available peripherals
if select(1,...) == "-?" then
  printUsage(
    "peripherals","Lists the available peripherals"
  )
  return
end

local _,perlist = coroutine.yield("BIOS:listPeripherals")

for per, functions in pairs(perlist) do
 print(per.." ", false)
end
print("") --New line