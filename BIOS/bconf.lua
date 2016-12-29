--The default configuation
--per ,err = P(peripheral,mountedName,configTable)

--Create a new cpu mounted as "CPU"
P("CPU")

--Create a new gpu mounted as "GPU"
P("GPU","GPU",{
  _ClearOnRender = true
})