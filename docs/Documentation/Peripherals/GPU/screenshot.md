# GPU.screenshot
---

Takes a screenshot of the canvas (without the cursor), and returns its imagedata.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local imgdata = GPU.screenshot(x, y, w, h)
```

---
### Arguments
---

* **x (number, nil) (Default:`0`):** The top-left X coord of the area to take the screenshot of.
* **y (number, nil) (Default:`0`):** The top-left Y coord of the area to take the screenshot of.
* **w (number):** The width of the area to take the screenshot of.
* **h (number):** The height of the area to take the screenshot of.


---
### Returns
---

* **imgdata ([Peripherals/GPU/imageData](/Documentation/Peripherals/GPU/objects/imageData/)):** The created imagedata object.

