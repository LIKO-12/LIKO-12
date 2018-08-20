# GPU.cursor
---

Sets the current active mouse cursor, or creates a new one.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Set the current mouse cursor:
---

```lua
local  = GPU.cursor(name, grap)
```


---
## Arguments
---

* **name (string):** The name of the cursor.
* **grap (boolean):** True -> Grap the cursor to the pixelated screen.


---
## Returns
---


---

# 2. Get the current mouse cursor:
---

```lua
local current = GPU.cursor()
```


---
## Arguments
---



---
## Returns
---

* **current (string):** The current active cursor name.

---

# 3. Create a new cursor:
---

```lua
local  = GPU.cursor(imgdata, name, hx, hy)
```


---
## Arguments
---

* **imgdata ():** The imagedata of the cursor.
* **name (string):** The name of the cursor.
* **hx (number):** The X coord of the cursor hot position.
* **hy (number):** The Y coord of the cursor hot position.


---
## Returns
---


---