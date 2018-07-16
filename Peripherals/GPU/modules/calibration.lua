--GPU: Calibations and graphics card info.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUKit, DevKit = ...
--luacheck: pop

local lg = love.graphics

local json = require("Engine.JSON")

local Path = GPUKit.Path
local CalibrationKit = GPUKit.Calibration

--==Local Variables==--

local _CanvasFormats = lg.getCanvasFormats()

--==Graphics card info==--

local gpuName, gpuVersion, gpuVendor, gpuDevice = lg.getRendererInfo() --Used to apply some device specific bugfixes.
if not love.filesystem.getInfo("/Misc/GPUInfo.txt","file") then love.filesystem.write("/Misc/GPUInfo.txt",gpuName..";"..gpuVersion..";"..gpuVendor..";"..gpuDevice) end

--==Graphics card supported canvases info==--

if not love.filesystem.getInfo("/Misc/GPUCanvasFormats.txt","file") then
  local formats = {}
  for k,v in pairs(_CanvasFormats) do
    if v then table.insert(formats,k) end
  end
  table.sort(formats)
  formats = table.concat(formats,"\n")
  local rformats = {}
  for k,v in pairs(lg.getCanvasFormats(true)) do
    if v then table.insert(rformats,k) end
  end
  table.sort(rformats)
  rformats = table.concat(rformats,"\n")
  love.filesystem.write("/Misc/GPUCanvasFormats.txt",formats.."\n\nReadable:\n\n"..rformats)
end

--==Calibration Process==--

local calibVersion,ofs = 1.4
if love.filesystem.getInfo("/Misc/GPUCalibration.json","file") then
  ofs = json:decode(love.filesystem.read("/Misc/GPUCalibration.json"))
  if ofs.version < calibVersion then --Redo calibration
    ofs = love.filesystem.load(Path.."scripts/calibrate.lua")()
    ofs.version = calibVersion
    love.filesystem.write("/Misc/GPUCalibration.json",json:encode_pretty(ofs))
  end
else
  ofs = love.filesystem.load(Path.."scripts/calibrate.lua")()
  ofs.version = calibVersion
  love.filesystem.write("/Misc/GPUCalibration.json",json:encode_pretty(ofs))
end

--==Custom Patches==--

if gpuVersion == "OpenGL ES 3.1 v1.r7p0-03rel0.b8759509ece0e6dda5325cb53763bcf0" then
  --GPU glitch fix for this driver, happens at my samsung j700h
  ofs.screen = {0,-1}
end

--==GPUKit Exports==--
CalibrationKit.Offsets = ofs