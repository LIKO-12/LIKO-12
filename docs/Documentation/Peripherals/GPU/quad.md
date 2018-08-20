# GPU.quad
---

Creates a new quad.

Quads can be used to select a part of an image to draw. In this way, one large images atlas (sheet) can be loaded, and then split up into sub-images.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
GPU.quad(x, y, w, h, sw, sh)
```

---
### Arguments
---

* **x (number):** The x coord of the quad's top-left corner.
* **y (number):** The y coord of the quad's top-left corner.
* **w (number):** The width of the quad.
* **h (number):** The height of the quad.
* **sw (number):** The width of the reference image.
* **sh (number):** The height of the reference image.

