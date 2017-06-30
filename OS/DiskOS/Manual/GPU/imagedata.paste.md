Paste into ImageData from another source ImageData.

---

#### Syntax:
```lua
imgdata:paste(simgdata, dx,dy, sx,sy, sw,sh)
```

---

#### Arguments:

* **<simgdata\> ([GPUImageData](imagedata.md))**: The source imagedata (To copy from).
* **[dx] (0) (Number)**: Destination top-left x position.
* **[dy] (0) (Number)**: Destination top-left y position.
* **[sx] (0) (Number)**: Source top-left x position.
* **[sy] (0) (Number)**: Source top-left y position.
* **[sw] (simgdata:width) (Number)**: Source width.
* **[sh] (simgdata:height) (Number)**: Source height.

---

#### Note:

The function returns the imagedata object itself, so it can be used for chain calls, ex:
```lua
img = imgdata:paste(...):image()
```