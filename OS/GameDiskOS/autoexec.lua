local term = require("terminal")

print("\nBooting Game...") flip() sleep(1)

term.execute("load","game")

while true do
  term.execute("run")
  printCursor(0,0,0) color(7) clear(0)
  print("Restarting Game...")
  sleep(1)
end