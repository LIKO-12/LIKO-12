--Pass the peripherals.

local Globals = (...) or {}

--Only the allowed ones ;)
local blocklist = { HDD = true, WEB = true, FDD = true, BIOS = true }
local perglob = {GPU = true, CPU = true, Keyboard = true, RAM = true} --The perihperals to make global not in a table.

local handledapis = BIOS.HandledAPIS()
for peripheral, funcList in pairs(handledapis) do
  if not blocklist[peripheral] then
    for funcName, func in pairs(funcList) do
      if funcName:sub(1,1) == "_" then
        funcList[funcName] = nil
      elseif perglob[peripheral] then
        Globals[funcName] = func
      end
    end
    
    Globals[peripheral] = funcList
  end
end

return Globals