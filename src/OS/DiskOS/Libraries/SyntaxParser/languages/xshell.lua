local function contains(t, e)
  for i = 1,#t do
    if t[i] == e then return true end
  end
  return false
end

local specials = {"&",";","$"}

local function token(stream, state)
  local result = nil

  if state.tokenizer == "base" then
    char = stream:next()
    if char == ";" then
      result = "chainer"
    elseif char == "&" then
      result = "conditionalChainer"
    elseif char == "$" then
      if stream:peek() == "(" then
      else
        stream:eatChain("[^"..table.concat(specials,"").."]")
        result = "assigner"
      end
    else
      result = "command"
      stream:eatChain("[^"..table.concat(specials,"").."]")
    end
  elseif state.tokenizer == "command" then
    char = stream:next()
    if char == " " and contains(specials,stream.peek()) then
      result = "base"
    end
  end

  return result
end

return {
  startState = {
    tokenizer = "base",
    starter = ""
  },
  token = token
}
