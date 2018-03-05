local stream = {}

stream.string = ""
stream.start = 1
stream.pos = stream.start

function stream:peek()
    local char = self.string:sub(self.pos, self.pos)
    if char ~= "" then return char else return nil end
end

function stream:match(pattern)
    local s, e = self.string:find(pattern, self.pos)
    if s and s == self.pos then
        self.pos = e + 1
        return true
    end
end

function stream:eat(pattern)
    local char = self.string:sub(self.pos, self.pos)
    if char:find(pattern) then
        self.pos = self.pos + 1
        return char
    end
end

function stream:eatWhile(pattern)
    local start = self.pos
    while self:eat(pattern) do end
    return self.pos > start
end

function stream:skipTo(char)
    local start, found = self.string:find(char, self.pos)
    if start and start >= self.pos then
        self.pos = found
        return true
    end
end

function stream:skipToEnd()
    self.pos = self.string:len()+1
end

function stream:eol()
    return self.pos > self.string:len()
end

function stream:next()
    if self.pos <= self.string:len() then
        char = self.string:sub(self.pos, self.pos)
        self.pos = self.pos + 1
        return char
    end
end

function stream:backUp(n)
    if self.pos > 1 then
        self.pos = self.pos - (n or 1)
        return true
    end
end

function stream:current()
    return self.string:sub(self.start, self.pos-1)
end

-- Constructor
return function(string)
    stream.string = string
    return stream
end