--GPU: Calibations and graphics card info.

--luacheck: push ignore 211
local Config, GPU, yGPU, GPUVars, DevKit = ...
--luacheck: pop

local lg = love.graphics

local json = require("Engine.JSON")

local Path = GPUVars.Path
local CalibrationVars = GPUVars.Calibration

--==Local Variables==--

local _CanvasFormats = lg.getCanvasFormats()

--==Graphics card info==--

local gpuName, gpuVersion, gpuVendor, gpuDevice = lg.getRendererInfo() --Used to apply some device specific bugfixes.
local gpuInfo = gpuName..";"..gpuVersion..";"..gpuVendor..";"..gpuDevice
if not love.filesystem.getInfo("/Miscellaneous/GPUInfo.txt","file") then love.filesystem.write("/Miscellaneous/GPUInfo.txt",gpuInfo) end

--==Graphics card supported canvases info==--

if not love.filesystem.getInfo("/Miscellaneous/GPUCanvasFormats.txt","file") then
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
  love.filesystem.write("/Miscellaneous/GPUCanvasFormats.txt",formats.."\n\nReadable:\n\n"..rformats)
end

--==Calibration Process==--

local calibVersion,ofs = 1.5
if love.filesystem.getInfo("/Miscellaneous/GPUCalibration.json","file") then
  ofs = json:decode(love.filesystem.read("/Miscellaneous/GPUCalibration.json"))
  if ofs.version < calibVersion or ofs.info ~= gpuInfo then --Redo calibration
    ofs = love.filesystem.load(Path.."scripts/calibrate.lua")()
    ofs.version = calibVersion
    ofs.info = gpuInfo
    love.filesystem.write("/Miscellaneous/GPUCalibration.json",json:encode_pretty(ofs))
  end
else
  ofs = love.filesystem.load(Path.."scripts/calibrate.lua")()
  ofs.version = calibVersion
  ofs.info = gpuInfo
  love.filesystem.write("/Miscellaneous/GPUCalibration.json",json:encode_pretty(ofs))
end

--==Custom Patches==--

if gpuVersion == "OpenGL ES 3.1 v1.r7p0-03rel0.b8759509ece0e6dda5325cb53763bcf0" then
  --GPU glitch fix for this driver, happens at my samsung j700h
  ofs.screen = {0,-1}
end

--==GPUVars Exports==--
CalibrationVars.Offsets = ofs