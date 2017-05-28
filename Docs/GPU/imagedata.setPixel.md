Set a pixel color in the imagedata.

---

#### Syntax:
```lua
imgdata:setPixel(x,y,c)
```

---

#### Arguments:

* **<x\> (Number)**: The pixel x position.
* **<y\> (Number)**: The pixel y position.
* **<c\> (Number)**: The new pixel color (0-15).

---

#### Note:

The function returns the imagedata object itself, so it can be used for chain calls, ex:
```lua
img = imgdata:setPixel(0,0,7):image()
```