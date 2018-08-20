# GPU.colorPalette
---

Allows you to read and modify the real RGBA values of a color in the palette.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Read the RGB values of a color:
---

```lua
local r, g, b = GPU.colorPalette(id)
```


---
#### Arguments
---

* **id (number):** The color id.


---
#### Returns
---

* **r (number):** The channel red value [0-225]
* **g (number):** The channel green value [0-225]
* **b (number):** The channel blue value [0-225]

---

# 2. Set the RGB values of a color:
---

```lua
GPU.colorPalette(id, r, g, b)
```


---
#### Arguments
---

* **id (number):** The color id.
* **r (number):** The channel red value [0-225]
* **g (number):** The channel green value [0-225]
* **b (number):** The channel blue value [0-225]

---

# 3. Reset the palette colors to their defaults (PICO-8 Palette):
---

```lua
GPU.colorPalette()
```

---