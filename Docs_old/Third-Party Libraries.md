DiskOS provides games with a set of useful third-party lua librarys.

---

## Middleclass:

---

Middleclass is an object-oriented library for Lua.

If you are familiar with Object Orientation in other languages (C++, Java, Ruby … ) then you will probably find this library very easy to use.

**It's available as `class` in the globals.**

* It has been used in bump.lk12 Demo, and in BatteryMan Game.

**Documentation:** [https://github.com/kikito/middleclass/wiki](https://github.com/kikito/middleclass/wiki)

**Sourcecode:** [https://github.com/kikito/middleclass](https://github.com/kikito/middleclass)

##### Example:

---

```lua
local Fruit = class('Fruit') -- 'Fruit' is the class' name

function Fruit:initialize(sweetness)
  self.sweetness = sweetness
end

Fruit.static.sweetness_threshold = 5 -- class variable (also admits methods)

function Fruit:isSweet()
  return self.sweetness > Fruit.sweetness_threshold
end

local Lemon = class('Lemon', Fruit) -- subclassing

function Lemon:initialize()
  Fruit.initialize(self, 1) -- invoking the superclass' initializer
end

local lemon = Lemon:new()

print(lemon:isSweet()) -- false
```

---

## Bump:

---

Lua collision-detection library for axis-aligned rectangles. Its main features are:

- bump.lua only does axis-aligned bounding-box (AABB) collisions. If you need anything more complicated than that (circles, polygons, etc.) give HardonCollider a look.
- Handles tunnelling - all items are treated as "bullets". The fact that we only use AABBs allows doing this fast.
- Strives to be fast while being economic in memory
- It's centered on detection, but it also offers some (minimal & basic) collision response
- Can also return the items that touch a point, a segment or a rectangular zone.
- bump.lua is gameistic instead of realistic.

**It's available as `bump` in the globals.**

* It has been used in bump.lk12 Demo, and in BatteryMan Game.

**Documentation:** [https://github.com/kikito/bump.lua/blob/master/README.md](https://github.com/kikito/bump.lua/blob/master/README.md)

**Sourcecode:** [https://github.com/kikito/bump.lua](https://github.com/kikito/bump.lua)

##### Example:

---

```lua
-- The grid cell size can be specified via the initialize method
-- By default, the cell size is 64
local world = bump.newWorld(50)

-- create two rectangles
local A = {name="A"}
local B = {name="B"}

-- insert both rectangles into bump
world:add(A,   0, 0,    64, 256) -- x,y, width, height
world:add(B,   0, -100, 32, 32)

-- Try to move B to 0,64. If it collides with A, "slide over it"
local actualX, actualY, cols, len = world:move(B, 0,64)

-- prints "Attempted to move to 0,64, but ended up in 0,-32 due to 1 collisions"
if len > 0 then
  print(("Attempted to move to 0,64, but ended up in %d,%d due to %d collisions"):format(actualX, actualY, len))
else
  print("Moved B to 100,100 without collisions")
end

-- prints the new coordinates of B: 0, -32, 32, 32
print(world:getRect(B))

-- prints "Collision with A"
for i=1,len do -- If more than one simultaneous collision, they are sorted out by proximity
  local col = cols[i]
  print(("Collision with %s."):format(col.other.name))
end

-- remove A and B from the world
world:remove(A)
world:remove(B)
```

---

## JSON:

---

An awesome Lua library for decoding and encoding JSON tables, with customizable options.

**It's available as `JSON` in the globals.**

**Documentation:** [https://github.com/RamiLego4Game/LIKO-12/blob/master/Engine/JSON.lua](https://github.com/RamiLego4Game/LIKO-12/blob/master/Engine/JSON.lua)

**Sourcecode:** [http://regex.info/blog/lua/json](http://regex.info/blog/lua/json)

##### Example:

---

```lua
local lua_value = JSON:decode(raw_json_text) -- decode example

local raw_json_text    = JSON:encode(lua_table_or_value)        -- encode example
local pretty_json_text = JSON:encode_pretty(lua_table_or_value) -- "pretty printed" version
```

---

## Lume:

---

A collection of functions for Lua, geared towards game development.

It very useful for tables operations.

**It's available as `lume` in the globals.**

**Documentation:** [https://github.com/rxi/lume/blob/master/README.md](https://github.com/rxi/lume/blob/master/README.md)

**Sourcecode:** [https://github.com/rxi/lume/](https://github.com/rxi/lume/)