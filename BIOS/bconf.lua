--The default configuation
--per ,err = P(peripheral,mountedName,configTable)

--Create a new virtual hdd system mounted as "HDD"
assert(P("HDD","HDD",{
  C = 1024*1024 * 25, --Measured in bytes, equals 50 megabytes
  D = 1024*1024 * 25 --Measured in bytes, equals 50 megabytes
}))

--Create a new cpu mounted as "CPU"
assert(P("CPU"))

--Create a new gpu mounted as "GPU"
assert(P("GPU","GPU",{
  --_LIKO_W = 8*48, --384
  --_LIKO_H = 8*32, --256
  _ClearOnRender = true
}))

--Create a new keyboard api mounted as "KB"
assert(P("Keyboard"))