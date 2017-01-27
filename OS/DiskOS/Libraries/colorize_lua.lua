--This file is taken from technomancy's polywell editor--
-- Take a table of lines and turn it into a table of {color, string,
-- color2, string2} which can be used by love.graphics.print.

--Colors table keys:text,keyword,number,comment,str
local lume = require("C://Libraries/lume")
local keywords = {"and", "break", "do", "else", "elseif", "end", "false",
                  "for", "function", "if", "in", "local", "nil", "not", "or",
                  "repeat", "return", "then", "true", "until", "while", }
local colors, comment_match
local function colorize_keyword(l, n, offset)
   -- hoo boy, not having access to | in lua patterns is a pain!
   -- if this code makes you cringe at the performance implications, just
   -- remember that luajit is faster than you could possibly hope for.
   -- (the longest file in the codebase, 1200 lines, colorizes in 0.3 seconds
   -- on a 2009-era core 2 duo thinkpad)
   if(n and n > #keywords) then return {colors.text, l} end
   local s,e = string.find(l, keywords[n or 1], offset, true)
   if(s and string.find(string.sub(l,s-1,s-1), "[%w_]") or
      (e and string.find(string.sub(l,e+1,e+1), "[%w_]"))) then
      -- if it's inside a larger word, no match!
      return colorize_keyword(l, n, e+1)
   elseif(s == 1) then
      return {colors.keyword, string.sub(l,1,e),
              unpack(colorize_keyword(string.sub(l, e+1)))}
   elseif(s) then
      local pre = colorize_keyword(string.sub(l,1, s-1))
      return lume.concat(pre, {colors.keyword, string.sub(l,s,e),
                               unpack(colorize_keyword(string.sub(l,e+1))) })
   else
      return colorize_keyword(l, (n or 1) + 1)
   end
end
local function colorize_number(l, offset)
   -- TODO: scientific notation, hex
   local s,e = string.find(l, "[\\.0-9]+", offset)
   if(s and string.find(string.sub(l,s-1,s-1), "[%w_]")) then
      return colorize_number(l, e+1) -- no numbers at the end of identifiers
   elseif(s == 1) then
      return {colors.number, string.sub(l,1,e),
              unpack(colorize_number(string.sub(l, e+1)))}
   elseif(s) then
      local line = colorize_keyword(string.sub(l, 1, s-1))
      return lume.concat(line, {colors.number, string.sub(l,s,e),
                                unpack(colorize_number(string.sub(l,e+1))) })
   else
      return colorize_keyword(l)
   end
end
local colorize_comment = function(l)
   comment_match = string.find(l, "[-][-]")
   if(comment_match == 1) then
      return {colors.comment, l}
   elseif(comment_match) then
      local line = colorize_number(string.sub(l, 1,comment_match-1))
      table.insert(line, colors.comment)
      table.insert(line, string.sub(l,comment_match))
      return line
   else
      return colorize_number(l)
   end
end
local function colorize_string(l)
   local s,e = string.find(l, "\"[^\"]*\"")
   if(s == 1) then
      return {colors.str, string.sub(l,1,e),
              unpack(colorize_comment(string.sub(l,e+1)))}
   elseif(s) then
      local pre = colorize_comment(string.sub(l, 1,s-1))
      if(comment_match) then
         table.insert(pre, colors.comment)
         table.insert(pre, string.sub(l,s))
         return pre
      else
         local post = colorize_string(string.sub(l,e+1))
         return lume.concat(pre, {colors.str, string.sub(l, s, e)}, post)
      end
   else
      return colorize_comment(l)
   end
end
return function(lines, color_table)
   colors = color_table
   local t = {}
   for _,l in ipairs(lines) do table.insert(t, colorize_string(l)) end
   return t
end