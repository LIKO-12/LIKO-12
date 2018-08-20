Sets the current active mouse cursor, or creates a new one.

---

##### Default cursors provided by DiskOS:

`normal`, `handrelease`, `handpress`, `hand`, `cross`, `point`, `draw`, `normal_white`, `pencil`, `bucket`, `eraser`, `picker`

---

## Usage:

---

### 1. Set the current mouse cursor:

---

#### Syntax:
```lua
cursor(name,grap)
```

---

#### Arguments:

* **<name\> (String)**: The name of the cursor.
* **[grap] (Boolean) (false)**: True -> Grap the cursor to the pixelated screen.

---

### 2. Get the current mouse cursor:

---

#### Syntax:
```lua
current, imgdata, hx, hy = cursor()
```

---

#### Returns:

* **current (String)**: The current active cursor name.

---

### 3. Create a new cursor:

---

#### Syntax:
```lua
cursor(imgdata,name,hx,hy)
```

---

#### Arguments:

* **<imgdata\> (GPUImageData)**: The imagedata of the cursor.
* **[name] (String) (`"default"`): The name of the cursor.
* **[hx] (Number) (`0`): The X coord of the cursor hot position.
* **[hy] (Number) (`0`): The Y coord of the cursor hot position.