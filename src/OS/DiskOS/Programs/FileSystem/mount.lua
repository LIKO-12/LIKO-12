local args = {...}

if #args < 1 then
  if fs.drives()["ZIP"] then
    fs.mountZIP()
    color(11) print("Unmounted successfully.")
    return 0
  end
end

if #args < 1 or args[1] == "-?" then
  printUsage("mount <zipPath>","Mounts a .ZIP file to the ZIP drive.",
             "mount --LIKOSRC","Mounts LIKO-12 SourceCode to the ZIP drive.",
             "mount","Unmount the .ZIP file from the ZIP drive.")
  color(7) print("Type 'drives' to check the current mounted ZIP")
  return
end

local term = require("terminal")

local source, zipData = args[1]
if source == "--LIKOSRC" then
  zipData = BIOS.getSRC() or ""
else
  source = term.resolve(source)

  if not fs.exists(source) then return 1, "File doesn't exist" end
  if fs.isDirectory(source) then return 1, "Couldn't mount a directory !" end

  zipData = fs.read(source)
end

local success = fs.mountZIP(zipData)
if success then
  color(11) print("Mounted successfully.")
else
  return 1, "Failed to mount."
end