local events = require("Engine.events")

return function(config) --A function that creates a new CPU peripheral.
  --The api starts here--
  local CPU = {}
  
  --Register a function to be called when love.update is called
  function CPU.hookUpdate(func)
    if type(func) ~= "function" then return false, "UpdateFunc should be a function, provided: "..type(func) end
    events:register("love:update",func)
    return true
  end
  
  return CPU
end