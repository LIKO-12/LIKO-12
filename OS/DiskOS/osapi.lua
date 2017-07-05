local tw, th = termSize()

function printUsage(...)
  local t = {...}
  color(9) 
  if #t > 2 then print("Usages:") else print("Usage:") end
  for k, line in ipairs(t) do
    if k%2 == 1 then
      color(7) 
      print(line,false)
    else
      local pre = t[k-1]
      local prelen = pre:len()
      local suflen = line:len()
      local toadd = tw - (prelen+suflen)
      if toadd > 0 then
        line = string.rep(" ",toadd)..line
      else
        line = "\n  "..line.."\n"
      end
      color(6)
      print(line)
    end
  end
end