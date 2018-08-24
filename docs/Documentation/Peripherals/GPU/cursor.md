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
GPU.cursor(name, grap)
```


---
#### Arguments
---

* **name (string):** The name of the cursor.
* **grap (boolean, nil) (Default:`"false"`):** True -> Grap the cursor to the pixelated screen.

---

# 2. Get the current mouse cursor:
---

```lua
local current = GPU.cursor()
```


---
#### Returns
---

* **current (string):** The current active cursor name.

---

# 3. Create a new cursor:
---

```lua
GPU.cursor(imgdata, name, hx, hy)
```


---
#### Arguments
---

* **imgdata ([Peripherals/GPU/imageData](/Documentation/Peripherals/GPU/objects/imageData/)):** The imagedata of the cursor.
* **name (string, nil) (Default:`"default"`):** The name of the cursor.
* **hx (number, nil) (Default:`0`):** The X coord of the cursor hot position.
* **hy (number, nil) (Default:`0`):** The Y coord of the cursor hot position.

---