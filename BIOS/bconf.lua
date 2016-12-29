--The default configuation
--per ,err = P(peripheral,mountedName,configTable)

--Create a new virtual hdd system mounted as "HDD"
P("HDD","HDD",{
  C = 1024*1024 * 50, --Measured in bytes, equals 50 megabytes
  D = 1024*1024 * 50 --Measured in bytes, equals 50 megabytes
})

--Create a new cpu mounted as "CPU"
P("CPU")

--Create a new gpu mounted as "GPU"
P("GPU","GPU",{
  _ClearOnRender = true
})