local keywords = {
    "and", "break", "do", "else", "elseif",
    "end", "false", "for", "function", "if",
    "in", "local", "nil", "not", "or",
    "repeat", "return", "then", "true", "until", "while"
}
local api = getAPI()
local callbacks = {"_draw","_init","_keypressed","_keyreleased","_mousemoved","_mousepressed","_mousereleased","_textinput","_touchcontrol","_touchmoved","_touchpressed","_touchreleased","_update","_wheelmoved"}

-- Convert values to keys
for _, list in ipairs({keywords, api, callbacks}) do
    for i, word in ipairs(list) do
        list[word] = true
        list[i] = nil
    end
end

function startState()
  return {
    tokenizer = "base",
  }
end

function token(stream, state)
  local result = nil

  if state.tokenizer == "base" then
      char = stream:next()
      -- Comment and multiline comment matching
      if char == "-" and stream:eat('%-') then
          if stream:match("%[%[") then
              state.tokenizer = "multilineComment"
          else
              stream:skipToEnd()
              result = "comment"
          end
      -- String matching
      elseif char == "\"" or char == "'" then
          if stream:skipTo(char) then
              stream:next()
          else
              stream:skipToEnd()
          end
          result = "string"
      -- Decimal numbers
      elseif char == '.' and stream:match('%d+') then
          result = 'number'
      -- Hex
      elseif char == "0" and stream:eat("[xX]") then
          stream:eatWhile("%x")
          result = "number"
      -- Ints and floats numbers
      elseif char:find('%d') then
          stream:eatWhile("%d")
          stream:match("\\.%d+")
          local nextChar = stream:peek() or "" -- TODO: Do this to hex and decimals too
          if not nextChar:find("[%w_]") then
              result = "number"
          end
      -- elseif operators[char] then
      --     return 'operator'
      -- Multiline string matching
      elseif char == "[" and stream:eat("%[") then
          state.tokenizer = "multilineString"
      -- Keyword matching                
      elseif char:find('[%w_]') then
          stream:eatWhile('[%w_]')
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

  if state.tokenizer == "multilineString" then
      if stream:skipTo("%]%]") then
          stream:next()
          state.tokenizer = "base"
      else
          stream:skipToEnd()
      end
      result = "string"
  elseif state.tokenizer == "multilineComment" then
      if stream:skipTo("%]%]") then
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