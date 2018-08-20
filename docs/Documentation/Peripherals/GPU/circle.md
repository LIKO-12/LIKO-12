# GPU.circle
---

Draws a circle on the screen.

---

?> The arguments can be passed in a table.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
GPU.circle(x, y, r, l, c, seg)
```

---
### Arguments
---

* **x (number):** The x coord of circle center.
* **y (number):** The y coord of circle center.
* **r (number):** The radius of circle.
* **l (boolean):** (false/nil) The circle will be filled, (true) The circle will have only lines (outline).
* **c (number):** The color of the circle (0-15), defaults to the active color.
* **seg (number):** The number of the segments used when drawing the circle.

