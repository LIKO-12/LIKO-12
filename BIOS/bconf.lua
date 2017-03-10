--The default configuation
--per ,err = P(peripheral,mountedName,configTable)

--Create a new cpu mounted as "CPU"
local CPU, CPUKit = assert(P("CPU"))

--Create a new gpu mounted as "GPU"
local GPU, GPUKit = assert(P("GPU","GPU",{
  --_LIKO_W = 8*48, --384
  --_LIKO_H = 8*32, --256
  _ClearOnRender = true,
  CPUKit = CPUKit
}))

--Create a new keyboard api mounted as "KB"
assert(P("Keyboard","Keyboard",{CPUKit = CPUKit, GPUKit = GPUKit}))

--Create a new virtual hdd system mounted as "HDD"
assert(P("HDD","HDD",{
  C = 1024*1024 * 25, --Measured in bytes, equals 50 megabytes
  D = 1024*1024 * 25 --Measured in bytes, equals 50 megabytes
}))
