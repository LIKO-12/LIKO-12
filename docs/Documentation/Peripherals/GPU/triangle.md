# GPU.triangle
---

Draws a triangle on the screen.

---

?> The arguments can be passed in a table

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
GPU.triangle(x1, y1, x2, y2, x3, y3, l, c)
```

---
### Arguments
---

* **x1 (number):** The first x coordinate of triangle vector.
* **y1 (number):** The first y coordinate of triangle vector.
* **x2 (number):** The second x coordinate of triangle vector.
* **y2 (number):** The second y coordinate of triangle vector.
* **x3 (number):** The third x coordinate of triangle vector.
* **y3 (number):** The third y coordinate of triangle vector.
* **l (boolean, nil) (Default:`"false"`):** (false/nil) The triangle will be filled, (true) The triangle will have only lines (outline).
* **c (number):** The color of triangle (0-15), defaults to the active color.

