local terminal = require("terminal")
local runtime = require("runtime")
local lume = require("libraries.lume")

-- use lume for serialization, which is so lame but good enough for nom
local pps = lume.serialize

local console = lume.clone(terminal)
console.textbuffer, console.currentLine = {}, 2

local pack = function(...) return {...} end

local compile = function(input)
  local chunk, err = loadstring("return " .. input)
  if(err and not chunk) then -- maybe it's a statement, not an expression
    return loadstring(input)
  else
    return chunk
  end
end

local eval = function(input, print)
  -- try runnig the compiled code in protected mode.
  local chunk, err = compile(input)
  if(not chunk) then
    print("! Compilation error: " .. (err or "Unknown error"))
    return false
  end

  local trace
  local result = pack(xpcall(chunk, function(e)
                               trace = debug.traceback()
                               err = e end))
  if(result[1]) then
    local output, i = pps(result[2]), 3
    -- pretty-print out the values it returned.
    while i <= #result do
      output = output .. ', ' .. pps(result[i])
      i = i + 1
    end
    print(output)
  else
    -- display the error and stack trace.
    print('! Evaluation error: ' .. err or "Unknown")
    for _,l in ipairs(lume.split(trace, "\n")) do
      print(l)
    end
  end
end

console._startup = function(self)
  for i=1,self.linesLimit do table.insert(self.textbuffer,"") end
  for i=1,self.linesLimit do table.insert(self.textcolors,8) end
  keyrepeat(true)
  self:tout("LUA CONSOLE")
  self:tout("> ", 8, true)
end

console._kpress = function(self, k,sc,ir)
  if k == "return" then
    local input = self.textbuffer[self.currentLine]:sub(3)
    self:tout("")
    eval(input, lume.fn(self.tout, self))
    self:tout("> ",8,true)
    self:_redraw()
  elseif k == "backspace" then
    self.textbuffer[self.currentLine] =
      self.textbuffer[self.currentLine]:sub(0,-2)
    self:_redraw()
  end
end

function console:_tinput(t)
  if self.textbuffer[self.currentLine]:len() < self.lengthLimit then
    self:tout(t,8,true)
  end
  self:_redraw()
end

return console
