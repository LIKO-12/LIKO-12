local perpath = select(1,...) --The path to the GPU folder.
--/Peripherals/GPUN/

return function(config) --A function that creates a new GPU peripheral.
  
  --GPU: the non-yielding APIS of the GPU.
  --yGPU: the yield APIS of the GPU.
  --GPUKit: Shared data between the GPU files.
  --DevKit: Shared data between the peripherals.
  local GPU, yGPU, GPUKit, DevKit = {}, {}, {}
  
  local function loadModule(name)
    love.filesystem.load(perpath.."modules/"..name..".lua")(config, GPU, yGPU, GPUKit, DevKit)
  end
  
  loadModule("window")
  
end