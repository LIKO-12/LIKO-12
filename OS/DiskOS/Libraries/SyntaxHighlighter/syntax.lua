local syntax = {}

local parser = require("Libraries/parser/parser")
local colorizer = require("Libraries/colorizer")

function syntax:setTheme(theme)
   colorizer:setTheme(theme)
end

function syntax:setSyntax(syntax)
   parser:loadParser(syntax)
end

function syntax:highlightLine(line, lineIndex)
    lines, colateral = self:highlightLines({line}, lineIndex)
    line = lines[1]
   return line, colateral
end

function syntax:highlightLines(lines, lineIndex)
   local highlightedLines = {}
   parsedLines, colateral = parser:parseLines(lines, lineIndex)
   for _, line in ipairs(parsedLines) do
      table.insert(highlightedLines, colorizer:colorizeLine(line))
   end
   return highlightedLines, colateral
end

return syntax