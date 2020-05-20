--Lua syntax parser

--Lua Keywords
local keywords = {
  "and", "break", "do", "else", "elseif",
  "end", "false", "for", "function", "if",
  "in", "local", "nil", "not", "or",
  "repeat", "return", "then", "true", "until", "while"
}

--Lua escapable characters
local escapable = {"a", "b", "f", "n", "r", "t", "v", "\\", '"', "'"}

--LIKO-12 API Functions
local api = _APIList

--LIKO-12 Callbacks
local callbacks = {"_draw","_draw30","_draw60","_init","_keypressed","_keyreleased","_mousemoved","_mousepressed","_mousereleased","_textinput","_touchcontrol","_touchmoved","_touchpressed","_touchreleased","_update","_update30","_update60","_wheelmoved","_filedropped","self"}

--Convert values to keys for instant searching
for _, list in ipairs({keywords, api, callbacks, escapable}) do
  for i=1, #list do
    list[list[i]] = true
    list[i] = nil
  end
end

local function token(stream, state)
  if state.tokenizer == "base" then
    local char = stream:next() --Read a character from the stream
    local pos = stream.pos --The position of the next character
    
      --Comment and multiline comment matching
    if char == "-" and stream:eat('%-') then --Parse the '--'
      if stream:match("^%[=*%[") then --It's a multilineComment
        state.tokenizer = "multilineComment"
        state.multilen = stream.pos - pos - 3
      else --It's a single line comment
        stream:skipToEnd() --The rest of the line is a comment
        return "comment"
      end
      
      --String matching
    elseif char == '"' or char == "'" then
      state.starter = char
      state.tokenizer = "string"
      return "string" -- Return immediatelly so quotes doesn't get affected by escape sequences
      
      -- Decimal numbers
    elseif char == '.' and stream:match('%d+') then
      return "number"
      
      -- Hex and Binary numbers
    elseif char == "0" and (stream:eat("[xX]") or stream:eat("[bB]")) then
      stream:eatChain("%x")
      return "number"
      
      -- Ints and floats numbers
    elseif char:find('%d') then
      stream:eatChain("%d")
      stream:match("\\.%d+")
      local nextChar = stream:peek() or "" -- TODO: Do this to hex and decimals too
      if not nextChar:find("[%w_]") then
        return "number"
      end
      
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
        return "keyword"
      elseif api[word] then
        return "api"
      elseif callbacks[word] then
        return "callback"
      end
    end
  end

  if state.tokenizer == "string" then
    local char = stream:next()
    if char == "\\" then
      local escaped = stream:peek()
      if escaped and escapable[escaped] then
        stream:next()
        return "escape"
      end
    elseif char == state.starter then
      state.starter = ""
      state.tokenizer = "base"
    else
      if stream:eol() then state.tokenizer = "base" end
    end
    
    return "string"

  elseif state.tokenizer == "multilineString" then
    local char = stream:next()
    
    if char == "\\" then
      local escaped = stream:peek()
      if escaped and escapable[escaped] then
        stream:next()
        return "escape"
      end
    elseif char == "]" and stream:match("^" .. string.rep("=", state.multilen) .. "%]") then
      state.tokenizer = "base"
    end
    
    return "string"

  elseif state.tokenizer == "multilineComment" then
    if stream:skipTo("%]" .. string.rep("=", state.multilen) .. "%]") then
      stream:next()
      state.tokenizer = "base"
    else
      stream:skipToEnd()
    end
    
    return "comment"
  end
end

return {
  startState = {
    tokenizer = "base",
    multilen = 0, --Multiline comment/string '==' number, example: [=[ COMMENT ]=] -> 1
    starter = ""
  },
  token = token
}