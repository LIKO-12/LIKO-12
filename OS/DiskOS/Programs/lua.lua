if select(1,...) == "-?" then
  printUsage(
    "lua","Starts Lua interpreter"
  )
  return
end

local history = {}

print("LuaJIT ".._VERSION)
print("Type 'exit' to exit")
pushColor()
while true do
  color(7) print("> ",false)
  local code = TextUtils.textInput(history); print("")
  if not code or code == "exit" then break end
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