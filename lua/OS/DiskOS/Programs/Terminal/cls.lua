if (...) == "-?" then
  printUsage(
    "cls","Clears the screen"
  )
  return
end

clear(0)
printCursor(0,0,0)