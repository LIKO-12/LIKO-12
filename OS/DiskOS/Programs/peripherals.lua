--List the available peripherals
local _,perlist = coroutine.yield("BIOS:listPeripherals")

print("") --New line
for per, functions in pairs(perlist) do
 print(per.." ", false)
end
print("") --New line