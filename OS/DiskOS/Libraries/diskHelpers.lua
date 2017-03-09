--Enter the while true loop and pull events, including the call of calbacks in _G
function eventLoop()
  while true do
    local name, a, b, c, d, e, f = pullEvent()
    if _G[name] and type(_G[name]) == "function" then
      _G[name](a,b,c,d,e,f)
    end
  end
end