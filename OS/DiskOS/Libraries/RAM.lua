--Create RAM api

local function KB(v) return v*1024 end

local RAM = {}

local InitLayout = {
  {736},    --0x0000 Meta Data (736 Bytes)
  {KB(12)}, --0x02E0 SpriteMap (12 KB)
  {288},    --0x32E0 Flags Data (288 Bytes)
  {KB(18)}, --0x3400 MapData (18 KB)
  {KB(13)}, --0x7C00 Sound Tracks (13 KB)
  {KB(20)}, --0xB000 Compressed Lua Code (20 KB)
  {KB(02)}, --0x10000 Persistant Data (2 KB)
  {128},    --0x10800 GPIO (128 Bytes)
  {768},    --0x10880 Reserved (768 Bytes)
  {64},     --0x10B80 Draw State (64 Bytes)
  {64},     --0x10BC0 Reserved (64 Bytes)
  {KB(01)}, --0x10C00 Free Space (1 KB)
  {KB(04)}, --0x11000 Reserved (4 KB)
  {KB(12)}, --0x12000 Label Image (12 KBytes)
  {KB(12),"VRAM"}  --0x15000 VRAM (12 KBytes)
}

--Initialize the RAM
function RAM.initialize()
  --Remove any existing sections
  local sections = _getSections()
  for i=#sections,1,-1 do _removeSection(i) end
  
  for id, data in ipairs(InitLayout) do
    _newSection(data[1], data[2])
  end
end

return RAM