--List the available peripherals
if select(1,...) == "-?" then
  printUsage(
    "peripherals","Lists the available peripherals"
  )
  return
end

local perlist = BIOS.Peripherals()

for per, type in pairs(perlist) do
  if type == per then
    print(per.." ", false)
  else
    print(per.."_("..type..") ", false)
  end
end

print("") --New line