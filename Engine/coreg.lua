--Corouting Registry: this file is responsible for providing LIKO12 it's api--
local coreg = {reg={}}

--Register a value to a specific key.
--If the value is a table, then the values in the table will be registered at key:tableValueKey
--If the value is a function, then it will be called instantly, and it must return true as the first argument to tell that it ran successfully.
--Else, the value will be returned to the liko12 code.
function coreg:register(value,key)
  local key = key or "none"
  if type(value) == "table" then
    for k,v in pairs(value) do
      self.reg[key..":"..k] = v
    end
  end
  self.reg[key] = value
end

--Trigger a value in a key.
--If the value is a function, then it will call it instant.
--Else, it will return the value.
--Notice that the first return value is a boolean of "did it ran successfully", if false, the second return value is the error message.
function coreg:trigger(key,...)
  local key = key or none
  if type(self.reg[key]) == "nil" then return false, "error, key not found !" end
  if type(self.reg[key]) == "function" then
    return self.reg[key](...)
  else
    return true, self.reg[key]
  end
end

--Returns the value registered in a specific key.
--Returns: value then the given key.
function coreg:get(key)
  local key = key or "none"
  return self.reg[key], key
end

--Returns a table containing the list of the registered keys.
--list[key] = type
function coreg:index()
  local list = {}
  for k,v in pairs(self.reg) do
    list[k] = type(v)
  end
  return list
end

--Returns a clone of the registry table.
function coreg:registry()
  local reg = {}
  for k,v in pairs(self.reg) do
    reg[k] = v
  end
  return reg
end

return coreg