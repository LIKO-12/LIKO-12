local term = require("terminal")

sleep(0.15) print("\nBooting Game...") sleep(0.2)

term.execute("load","game")

while true do
  term.execute("run")
  printCursor(0,0,0) color(7) clear(0)
  print("Restarting Game...")
  sleep(1)
end