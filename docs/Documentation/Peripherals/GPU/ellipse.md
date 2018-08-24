# GPU.ellipse
---

Draws an ellipse on the screen.

---

?> The arguments can be passed in a table

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
GPU.ellipse(x, y, rx, ry, l, r, seg)
```

---
### Arguments
---

* **x (number):** The x coord of ellipse center.
* **y (number):** The y coord of ellipse center.
* **rx (number):** The radius of the ellipse along the x-axis (half the ellipse's width).
* **ry (number):** The radius of the ellipse along the y-axis (half the ellipse's height).
* **l (boolean, nil) (Default:`"false"`):** (false/nil) The ellipse will be filled, (true) The ellipse will have only lines (outline).
* **r (number):** The color of the ellipse (0-15), defaults to the active color.
* **seg (number):** The number of the segments used when drawing the ellipse.

