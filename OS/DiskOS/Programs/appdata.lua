if select(1,...) and select(1,...) == "-?" then
  printUsage("appdata","Open LIKO-12 appdata folder in the host os explorer")
  return
end

openAppData("/")