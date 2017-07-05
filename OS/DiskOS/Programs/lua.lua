if select(1,...) == "-?" then
  printUsage(
    "lua","Starts Lua interpreter"
  )
  return
end

print("LuaJIT ".._VERSION)
pushColor()
while true do
  color(7) print("> ",false)
  local code = input(); print("")
  if not code then break end
  local chunk, err = loadstring(code)
  if not chunk then
    color(8) print("C-ERR: "..tostring(err))
  else
    popColor()
    local ok, err = pcall(chunk)
    pushColor()
    if not ok then
      color(8) print("R-ERR: "..tostring(err))
    else
      print("")
    end
  end
end