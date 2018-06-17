local keywords = {
  "and", "break", "do", "else", "elseif",
  "end", "false", "for", "function", "if",
  "in", "local", "nil", "not", "or",
  "repeat", "return", "then", "true", "until", "while"
}
local api = getAPI()
local callbacks = {"_draw","_draw30","_draw60","_init","_keypressed","_keyreleased","_mousemoved","_mousepressed","_mousereleased","_textinput","_touchcontrol","_touchmoved","_touchpressed","_touchreleased","_update","_update30","_update60","_wheelmoved","_filedropped","self"}
local escapable = {"a", "b", "f", "n", "r", "t", "v", "\\", "\"", "'"}

-- Convert values to keys
for _, list in ipairs({keywords, api, callbacks, escapable}) do
  for i, word in ipairs(list) do
    list[word] = true
    list[i] = nil
  end
end

local function startState()
  return {
    tokenizer = "base",
    starter = ""
  }
end

local function token(stream, state)
  local result = nil

  if state.tokenizer == "base" then
    local char = stream:next()
    local pos = stream.pos
    -- Comment and multiline comment matching
    if char == "-" and stream:eat('%-') then
      if stream:match("^%[=*%[") then
        state.multilen = stream.pos - pos - 3
        state.tokenizer = "multilineComment"
      else
        stream:skipToEnd()
        result = "comment"
      end
      -- String matching
    elseif char == '"' or char == "'" then
      state.starter = char
      state.tokenizer = "string"
      return "string" -- Return immediatelly so quotes doesn't get affected by escape sequences
      -- Decimal numbers
    elseif char == '.' and stream:match('%d+') then
      result = 'number'
      -- Hex
    elseif char == "0" and stream:eat("[xX]") then
      stream:eatChain("%x")
      result = "number"
      -- Ints and floats numbers
    elseif char:find('%d') then
      stream:eatChain("%d")
      stream:match("\\.%d+")
      local nextChar = stream:peek() or "" -- TODO: Do this to hex and decimals too
      if not nextChar:find("[%w_]") then
        result = "number"
      end
      -- elseif operators[char] then
      --     return 'operator'
      -- Multiline string matching
    elseif char == "[" and stream:match("^=*%[") then
      state.multilen = stream.pos - pos - 1
      state.tokenizer = "multilineString"
      return "string"
      -- Keyword matching
    elseif char:find('[%w_]') then
      stream:eatChain('[%w_]')
      local word = stream:current()
      if keywords[word] then
        result = "keyword"
      elseif api[word] then
        result = "api"
      elseif callbacks[word] then
        result = "callback"
      end
    end
  end

  if state.tokenizer == "string" then
    local char = stream:next()
    result = "string"
    if char == "\\" then
      local escaped = stream:peek()
      if escaped and escapable[escaped] then
        stream:next()
        result = "escape"
      end
    elseif char == state.starter then
      state.starter = ""
      state.tokenizer = "base"
      --else
      --    stream:skipToEnd()
    else
      if stream:eol() then state.tokenizer = "base" end
    end

  elseif state.tokenizer == "multilineString" then
    local char = stream:next()
    result = "string"
    if char == "\\" then
      local escaped = stream:peek()
      if escaped and escapable[escaped] then
        stream:next()
        result = "escape"
      end
    elseif char == "]" and stream:match("^" .. string.rep("=", state.multilen) .. "%]") then
      state.tokenizer = "base"
    end

  elseif state.tokenizer == "multilineComment" then
    if stream:skipTo("%]" .. string.rep("=", state.multilen) .. "%]") then
      stream:next()
      state.tokenizer = "base"
    else
      stream:skipToEnd()
    end
    result = "comment"
  end

  return result
end

return {
  startState = startState,
  token = token
}