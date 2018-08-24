# GPU.rect
---

Draws a rectangle on the screen.

---

?> The arguments can be passed in a table

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
GPU.rect(x, y, w, h, l, c)
```

---
### Arguments
---

* **x (number):** The top-left x position of the rectangle.
* **y (number):** The top-left y position of the rectangle.
* **w (number):** The width of rectangle.
* **h (number):** The height of rectangle.
* **l (boolean, nil) (Default:`"false"`):** (false/nil) The rectangle will be filled, (true) The rectangle will have only lines (border).
* **c (number):** The color of the rectangle (0-15), defaults to the active color.

