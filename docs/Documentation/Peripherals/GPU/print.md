# GPU.print
---

Prints text to the screen, uses the current active color.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Print at a specific position on the screen with wrapping mode
---

```lua
local  = GPU.print(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
```


---
## Arguments
---

* **text (string):** The text to draw.
* **x (number):** The X coord to draw at.
* **y (number):** The y coord to draw at.
* **limit (number):** Wrap the line after this many horizontal pixels.
* **align (string):** The alignment.
* **r (number):** Rotation (radians).
* **sx (number):** Scale factor (x-axis).
* **sy (number):** Scale factor (y-axis).
* **ox (number):** Origin offset (x-axis).
* **oy (number):** Origin offset (y-axis).
* **kx (number):** Shear factor (x-axis).
* **ky (number):** Shear factor (y-axis).


---
## Returns
---


---

# 2. Print at a specific position on the screen without wrapping.
---

```lua
local  = GPU.print(text, x, y, false, false, r, sx, sy, ox, oy, kx, ky)
```


---
## Arguments
---

* **text (string):** The text to draw.
* **x (number):** The X coord to draw at.
* **y (number):** The y coord to draw at.
* **false (boolean):** literal
* **false (boolean):** literal
* **r (number):** Rotation (radians).
* **sx (number):** Scale factor (x-axis).
* **sy (number):** Scale factor (y-axis).
* **ox (number):** Origin offset (x-axis).
* **oy (number):** Origin offset (y-axis).
* **kx (number):** Shear factor (x-axis).
* **ky (number):** Shear factor (y-axis).


---
## Returns
---


---

# 3. Print in terminal grid way.
---

```lua
local  = GPU.print(text)
```


---
## Arguments
---

* **text (string):** The text to draw.


---
## Returns
---


---

# 4. Print in terminal grid without auto newline.
---

```lua
local  = GPU.print(text, "false")
```


---
## Arguments
---

* **text (string):** The text to draw.
* **`"false"` (boolean)**


---
## Returns
---


---

# 5. Print in terminal grid directly without wrapping nor updating the cursor pos.
---

```lua
local  = GPU.print(text, "false", "true")
```


---
## Arguments
---

* **text (string):** The text to draw.
* **`"false"` (boolean)**
* **`"true"` (boolean)**


---
## Returns
---


---