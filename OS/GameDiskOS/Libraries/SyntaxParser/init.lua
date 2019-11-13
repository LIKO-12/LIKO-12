local newStream = require("Libraries.SyntaxParser.stream")

local function cloneTable(from, to, old)
  local c = to or {}
  local ch = false --Changed ? (when comparing from with old)

  for k,v in pairs(from) do
    if type(v) == "table" then
      if old and type(old[k]) ~= "table" then
        ch = true
        c[k] = cloneTable(v)
      else
        local c2, ch2 = cloneTable(v,{},old and old[k])
        c[k] = c2
        ch = ch2 or ch
      end
    else
      c[k] = v
      if old and v ~= old[k] then ch = true end
    end
  end

  return c, ch
end

local parser = {}

parser.parser = {}
parser.cache = {}
parser.state = nil

function parser:loadParser(language)
  self.cache = {}
  self.state = nil
  self.parser = require("Libraries.SyntaxParser.languages."..language)
end

function parser:previousState(lineIndex)
  lineIndex = lineIndex -1
  while lineIndex > 0 do
    if self.cache[lineIndex] then return self.cache[lineIndex] end
    lineIndex = lineIndex -1
  end
  return false
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
  for i=1, #lines do
    local line = lines[i]
    local lineID = lineIndex + i - 1
    
    self.state = {}

    -- Copy previous line state table, or create a new one if needed.
    -- TODO: language should provide a copy method.
    local tempState = self.cache[lineID - 1] --Pervious line
    or self:previousState(lineIndex) --Any pervious line
    or self.parser.startState --The start state provided by the parser
    
    cloneTable(tempState, self.state)

    -- Backup previous state of the current line
    local previousState = {}
    if self.cache[lineID] then
      cloneTable(self.cache[lineID], previousState)
    end

    -- Process line
    result[#result + 1] = parser:parseLine(line)

    -- Copy the processd state to cache.
    -- Also checks if this is the last line and its change is colateral.
    self.cache[lineID] = {}
    if i == # lines then
      if select(2,cloneTable(self.state, self.cache[lineID], previousState)) then colateral = true end
    else
      cloneTable(self.state, self.cache[lineID])
    end
  end
  return result, colateral
end

function parser:parseLine(line)
  local result = {}
  local stream = newStream(line)

  while not stream:eol() do
    local token = self.parser.token(stream, self.state)
    result[#result + 1] = token or "text"
    result[#result + 1] = stream:current() --The text read by the tokenizer
    stream.start = stream.pos
  end

  if #result == 0 then return {"text",  line} end
  return result
end

return parser