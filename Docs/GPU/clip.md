Sets the region that the GPU can draw on.

---

## Usage:

---

### 1. Enable clipping:

---

#### Syntax:
```lua
clip(x,y,w,h)
```

---

#### Arguments:

* **<x\> (Number)**: The top-left X coord of the clipping area.
* **<y\> (Number)**: The top-left Y coord of the clipping area.
* **<w\> (Number)**: The width of the clipping area.
* **<h\> (Number)**: The height of the clipping area.

---

### Note:

The arguments can be passed in a table:
```lua
clip( {x,y, w,h} )
```

---

### 2. Disable clipping:

---

#### Syntax:
```lua
clip()
```