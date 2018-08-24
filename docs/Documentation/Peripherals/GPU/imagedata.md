# GPU.imagedata
---

Creates a new imagedata object, which can be used for images processing (Set pixels, Get Pixels, encode, export, etc...).

---

?> All transparent pixels and all colors that are not from the palette will be loaded as black!

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local imgdata = GPU.imagedata(data)
```

---
### Arguments
---

* **data (string):** The image data, (png binary string or in lk12 format)


---
### Returns
---

* **imgdata ([Peripherals/GPU/imageData](/Documentation/Peripherals/GPU/objects/imageData/)):** The created imagedata object.

