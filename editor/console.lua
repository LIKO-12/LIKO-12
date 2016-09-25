local terminal = require("terminal")
local runtime = require("runtime")
local lume = require("libraries.lume")

-- use lume for serialization, which is so lame but good enough for nom
local pps = lume.serialize

local console = lume.clone(terminal) --Clone the terminal
console._kpress = nil
console.textbuffer, console.textcolors, console.currentLine = {}, {}, 1
console.lengthLimit = 45
console.linesLimit = 14

local pack = function(...) return {...} end

local eval = function(input, console_print)
  -- try runnig the compiled code in protected mode.
  console.G.print = console_print
  local chunk, err = runtime:compile(input, console.G)
  if(not chunk) then
    console_print("! Compilation error: " .. (err or "Unknown error"),10)
    print("! Compilation error: " .. (err or "Unknown error"))
    return false
  end

  local trace
  local result = pack(xpcall(chunk, function(e) trace = debug.traceback() err = e end))
  if(result[1]) then
    local output, i = pps(result[2]), 3
    -- pretty-print out the values it returned.
    while i <= #result do
      output = output .. ', ' .. pps(result[i])
      i = i + 1
    end
    console_print(output,7)
  else
    -- display the error and stack trace.
    console_print('! Evaluation error: ' .. (err or "Unknown"))
    print('! Evaluation error: ' .. (err or "Unknown"))
    for _,l in ipairs(lume.split(trace, "\n")) do
      console_print(l,10)
      print(l)
    end
  end
end

function console:_init()
  api.keyrepeat(true)
  local cls = function()
    console.textbuffer, console.textcolors, console.currentLine = {}, {}, 1
    for i=1,self.linesLimit do table.insert(self.textbuffer,"") end
    for i=1,self.linesLimit do table.insert(self.textcolors,8) end
  end
  local function reset()
    self.G = runtime.newGlobals()
    self.G.cprint = print
    local code = require("editor.code"):export()
    local chunk = runtime:compile(code, self.G)
    -- we ignore compile errors here; I think that is OK, but maybe warn?
    if(chunk) then chunk() end
    self.G.reset = reset
    self.G.cls = cls
    cls()
    self:tout("LUA CONSOLE", 8)
    self:tout("> ", 8, true)
  end
  reset()
end

function console:_redraw() --Patched this to restore the editor ui
  api.rect(1,9,192,128-16,6)
  for line,text in ipairs(self.textbuffer) do
    api.color(self.textcolors[line])
    if text == "-[[liko12]]-" then --THE SECRET PHASE
      api.SpriteGroup(67,9,line*8,6,1,1,1,api.EditorSheet)
    else
      api.print_grid(text,1,line+1)
    end
  end
end

function console:_update(dt)
  self.blinktimer = self.blinktimer+dt if self.blinktimer > self.blinktime then self.blinktimer = self.blinktimer - self.blinktime  self.blinkstate = not self.blinkstate end
  local curlen = self.textbuffer[self.currentLine]:len()
  api.color(self.blinkstate and 9 or 6)
  api.rect(curlen > 0 and ((curlen)*4+3) or 10,(self.currentLine)*8+2,4,5)
end

console.keymap = {
  ["return"] = function(self)
    local input = self.textbuffer[self.currentLine]:sub(3)
    self:tout("")
    eval(input, lume.fn(self.tout, self))
    self:tout("> ",8,true)
  end,

  ["backspace"] = function(self)
    self.textbuffer[self.currentLine] =
      self.textbuffer[self.currentLine]:sub(0,-2)
  end,
}

function console:_tinput(t)
  if t == "\\" then return end --This thing is so bad, so GO AWAY
  if self.textbuffer[self.currentLine]:len() < self.lengthLimit then
    self:tout(t,8,true)
  end
  self:_redraw()
end

return console
