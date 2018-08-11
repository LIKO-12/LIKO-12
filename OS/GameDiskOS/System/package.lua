local GameDiskOS = fs.drive() == "GameDiskOS"

--Reimplement the Lua package library
package = {}

package.loaded = {}
package.preload = {}
package.searchers = {}

package.path = GameDiskOS and "GameDiskOS:/?.lua;GameDiskOS:/?/init.lua;./?.lua;./?/init.lua" or "D:/OS/?.lua;D:/OS/?/init.lua;C:/?.lua;C:/?/init.lua;./?.lua;./?/init.lua"
package.cpath = "" --It's not used

package.config = "/\n;\n?\n!\n-"

function package.loadlib() end --Just for compatibility

function package.searchpath(name,path,sep,rep)
  if type(name) ~= "string" then return error("bad argument #1 to '?' (string expected, got "..type(name)..")") end
  if type(path) ~= "string" then return error("bad argument #2 to '?' (string expected, got "..type(path)..")") end
  local sep = tostring(sep or ".")
  local dirs, separator, replace = string.match(package.config,"(.-)\n(.-)\n(.-)\n")
  local rep = tostring(rep or dirs)
  
  --Escape magic characters
  sep = sep:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
  rep = rep:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
  separator = separator:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
  replace = replace:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
  
  name = name:gsub(sep,rep):gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
  path = path:gsub(replace,name)
  
  local errmsg = ""
  
  if path:gsub(-1,-1) ~= ";" then path = path..";" end
  for p in string.gmatch(path,"(.-);") do
    local presolved = p
    if fs.exists(presolved) then
      return presolved
    else
      errmsg = "\nno file'"..presolved.."'"
    end
  end
  
  return nil, errmsg
end

--Create default searchers
package.searchers[1] = function(modname, arg)
  local errmsg = ""
  if package.preload[modname] then
    if type(package.preload[modname]) ~= "function" then
      errmsg = "invalid field package.preload['"..modname.."']"
    end
    return package.preload[modname], arg or modname
  else
    errmsg = "\nno field package.preload['"..modname.."']"
  end
  
  return nil, errmsg
end

package.searchers[2] = function(modname,arg)
  local path, err = package.searchpath(modname,package.path)
  local errmsg = ""
  
  if path then
    local chunk, err = fs.load(path)
    if not chunk then errmsg = errmsg.."\nfailed to load: "..err else
      return chunk, arg or modname, path
    end
  end
  
  return nil, errmsg
end

function require(modname,arg)
  if type(modname) ~= "string" then return error("bad argument #1 to '?' (string expected, got "..type(modname)..")") end
  if package.loaded[modname] then return package.loaded[modname] end
  local path, err = package.searchpath(modname,package.path)
  if package.loaded[path] then return package.loaded[path] end
  local sn = 0 --Searcher number
  local errmsg = "module '"..modname.."' not found:"
  while true do
    sn = sn + 1
    if not package.searchers[sn] then break end
    local result, arg, newname = package.searchers[sn](modname,arg)
    if result then
      if newname then modname = newname end
      local ok, err = pcall(result,arg)
      if not ok then return error("Failed to load module: "..tostring(err)) end
      package.loaded[modname] = err
      return package.loaded[modname]
    else
      errmsg = errmsg..(arg or "")
    end
  end
  
  return error(errmsg)
end