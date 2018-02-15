The map object API

---

A new map object can be created by calling:

```lua
newMap = MapObj(w,h,sheet)
```

- `w,h` are the size of the map in cells.
- `sheet` is the Spritesheet to draw the sprites from, pass in `SpriteMap` for the SpriteEditor sheet.

---

The Tilemap Editor map is loaded and exposed as a global value: `TileMap`

---

## Map functions:

---

### - Map:map(func)

---

If called with a function, it will be called on everycell with `x,y,sprid` args, and that function can return an new tileid to set.

If called with no args, it will return the map table, structured this way `maptable[x][y] = tileid`, note that editing this table will effect the data inside the map object, you better shallow copy it using `lume` (a third-party library).

---

### - Map:cell(x,y,newID)

---

If called with `newID`, it will set that cell to the given `tileid`.

Otherwise, it will return the `tileid`.

---

### - Map:cut(x,y,w,h)

---

It will copy a part of the map, and puts it in a new map object, which is returned.

Note that `x,y,w,h` are optional, so `clone = Map:cut()` is a good way to clone the map.

---

### - Map:size(), Map:width(), Map:height()

---

Returns the map dimensions in cells.

---

### - Map:draw(dx,dy,x,y,w,h,sx,sy,sheet)

---

Draws the map.

- The drawing position is `dx,dy` in pixels.
- `x,y,w,h` are optional, and used to specify the part of the map to draw.
- `sx,sy` are scale factor, they are option.
- `sheet` is optional, the spritesheet to draw the sprites from, defaults to `SpriteMap`.

---

### - Map:export()

---

Serialize the map into a string and returns it.

---

### - Map:import(data)

---

Deserialize a map string.