# GPU.printCursor
---

Changes the print cursor position used by `print()` in the grid variant.

---

?> The positions are on a characters grid, the size of the grid can be requested from `termSize()`.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Set cursor position:
---

```lua
GPU.printCursor(x, y, bgcolor)
```


---
#### Arguments
---

* **x (number):** The X coord of the cursor in characters, defaults to the current X coord.
* **y (number):** The Y corrd of the cursor in characters, defaults to the current Y coord.
* **bgcolor (number):** The background color used when printing (**-1**,**15**), **-1** means no background, defaults to the current background color.

---

# 2. Get cursor position
---

```lua
local x, y, bgcolor = GPU.printCursor()
```


---
#### Returns
---

* **x (number):** The current X coord of the cursor in characters.
* **y (number):** The current Y corrd of the cursor in characters.
* **bgcolor (number):** The current background color.

---