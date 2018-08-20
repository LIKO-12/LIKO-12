Takes a screenshot of the canvas (without the cursor), and returns it's imagedata

---

#### Syntax:
```lua
imgdata = screenshot(x,y,w,h)
```

---

#### Arguments:

* **[x] (Number) (0)**: The top-left X coord of the area to take the screenshot of.
* **[y] (Number) (0)**: The top-left Y coord of the area to take the screenshot of.
* **[w] (Number) (ScreenWidth)**: The width of the area to take the screenshot of.
* **[h] (Number) (ScreenHeight)**: The height of the area to take the screenshot of.

---

#### Returns:

* **imgdata (GPUImageData)**: The created imagedata object.

---

##### See also:

* [imagedata()](imagedata.md)
* [imagedata:image()](imagedata.image.md)