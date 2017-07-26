local parser = {}

parser.parser = {}
parser.cache = {}
parser.state = nil

function parser:loadParser(language)
   -- TODO: Factory! https://github.com/luarocks/lua-style-guide#modules
   local chunk, err = fs.load("C:/Libraries/parser/languages/"..language..".lua")
   if not chunk then
      self.parser = {}
      return false
   else
      self.parser = chunk()
   end

end

function parser:previousState(lineIndex)
  local record = 0
  for i, state in pairs(self.cache) do
    if i >= lineIndex then break end
    if i > record then record = i end
  end
  if record > 0 then return self.cache[record] else return false end
end


function parser:parseLines(lines, lineIndex)
    local result = {}

    -- Forget all states after the modified line
    for i, state in pairs(self.cache) do
      if i > lineIndex then
        self.cache[i] = nil
      end
    end

    -- Process lines
    local colateral = false
    for i, line in ipairs(lines) do
      self.state = {}

      -- Copy previous line state table, or create a new one if needed.
      -- TODO: language should provide a copy method.
      local tempState = self.cache[lineIndex + i - 2]
        or self:previousState(lineIndex)
        or self.parser.startState()
      for k,v in pairs(tempState) do
        self.state[k] = v
      end

      -- Backup previous state of the current line
      local previousState = {}
      if self.cache[lineIndex + i - 1] then
        for k,v in pairs(self.cache[lineIndex + i - 1]) do
          previousState[k] = v
        end
      end
      
      -- Process line
      table.insert(result, parser:parseLine(line, lineIndex + i - 1))

      -- Copy the processd state to cache.
      -- Also checks if this is the last line and its change is colateral.
      self.cache[lineIndex + i - 1] = {}
      for k,v in pairs(self.state) do
        if i == #lines and previousState[k] ~= self.state[k] then colateral = true end
        self.cache[lineIndex + i - 1][k] = v
      end
    end
    return result, colateral
end

function parser:parseLine(line, lineIndex)
    local result = {}
    local chunk = fs.load("C:/Libraries/parser/stream.lua") -- TODO: Im sure that this can be improved
    local stream = chunk()(line)

    while not stream:eol() do
        token = self.parser.token(stream, self.state)
        table.insert(result, token or 'text')
        table.insert(result, stream:current())
        stream.start = stream.pos
    end

    if #result == 0 then return {'text',  line} end
    return result
end

return parser