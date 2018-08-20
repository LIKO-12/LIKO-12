# GPU.clip
---

Sets the region that the GPU can draw on.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Enable clipping:
---

```lua
GPU.clip(x, y, w, h)
```

?> The arguments can be passed in a table.

---


---
#### Arguments
---

* **x (number):** The top-left X coord of the clipping area.
* **y (number):** The top-left Y coord of the clipping area.
* **w (number):** The width of the clipping area.
* **h (number):** The height of the clipping area.

---

# 2. Disable clipping:
---

```lua
GPU.clip()
```

---