--Imports files--
--For now it imports images--

local source = select(1,...)
local distination = select(2,...)

print("") --New line

if not source then color(9) print("Must provide path to the source file") return end