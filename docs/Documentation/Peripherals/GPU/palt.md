# GPU.palt
---

Makes a specific color transparent or not, by default the color 0 is transparent.

---

?> This only affects images.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1.  Make a specific color transparent or not.
---

```lua
GPU.palt(color, transparent)
```


---
#### Arguments
---

* **color (number):** The color id (0-15).
* **transparent (boolean, nil) (Default:`"nil"`):** (true) The color will be transparent, (false/nil) The color will be opaque.

---

# 2. Reset the colors to it's default.
---

```lua
GPU.palt()
```

---