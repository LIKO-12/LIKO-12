local eapi = select(1,...) --The editor library is provided as an argument

local se = {} --Sprite Editor

function se:entered()
  eapi:drawUI()
end

function se:leaved()
  
end

return se