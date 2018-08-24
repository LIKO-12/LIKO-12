# GPU.pal
---

Maps a color in the palette to another color.

---

?> There are 2 palettes in LIKO-12: The Images palette which affects images only. And the Drawing palette which affects all other GPU functions.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Reset the whole palette.
---

```lua
GPU.pal(A, B, palette)
```


---
#### Arguments
---

* **A (boolean, number):** The color to replace, or false for all
* **B (number):** The color which will replace A
* **palette (number, boolean):** (0) will reset the color in the Drawing palette only, (1) will reset the color in the Images palette only, (nil/false) will reset the color in both palettes.

---

# 2. Reset a specific color to it's default.
---

```lua
GPU.pal(color, false, p)
```


---
#### Arguments
---

* **color (number):** The color to reset to it's default.
* **false (boolean):** literal
* **p (number, boolean):** (0) will reset the color in the Drawing palette only, (1) will reset the color in the Images palette only, (nil/false) will reset the color in both palettes.

---