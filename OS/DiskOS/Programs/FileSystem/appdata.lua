if select(1,...) == "-?" then
  printUsage(
    "appdata","Open LIKO-12 appdata folder in the host os explorer",
    "appdata --path","Shows the real path of the appdata folder"
  )
  return
end

if isMobile() or select(1,...) == "--path" then
  color(9) print("Appdata folder location: ")
  color(6) print(getSaveDirectory().."/")
else
  openAppData("/")
end