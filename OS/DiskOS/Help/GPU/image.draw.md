Draws the image on the screen.

---

#### Syntax:
```lua
img:draw(x,y,r,sx,sy,q) --Dont's forget the ':'
```

---

#### Arguments:

* **[x] (0) (Number)**: The top-left image corner x position.
* **[y] (0) (Number)**: The top-left image corner y position.
* **[r] (0) (Number)**: The image rotation in **radians**.
* **[sw] (1) (Number)**: The image width scale.
* **[sh] (1) (Number)**: The image height scale.
* **[q] (GPUQuad)**: Optional, A quad to draw the image with, check [GPU.quad](quad.md) for more info.

---

#### Note:

The function returns the image object itself, so it can be used for chain calls.