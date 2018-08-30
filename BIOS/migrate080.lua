--Migrating script from LIKO-12 0.8.0 and earlier.
local HandledAPIS = ...

--Peripherals
local GPU = HandledAPIS.GPU
local CPU = HandledAPIS.CPU
local fs = HandledAPIS.HDD

--Filesystem identity
local nIdentity = love.filesystem.getIdentity()
local oIdentity = "liko12"

--Helper functions
local function msg(...)
  GPU._systemMessage(table.concat({...}," "),3600,0,7)
  CPU.sleep(0)
end

--Activate old identity
local function activate()
  love.filesyste.setIdentity(oIdentity)
end

--Deactivate old identity
local function deactivate()
  love.filesystem.setIdentity(nIdentity)
end

--Start migrating
msg("Migrating your old data...")



GPU._systemMessage("",0)