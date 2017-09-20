Sets a sprite flag.

---

## Usage:

---

### 1. Set the whole flag byte:

---

#### Syntax:
```lua
fset(sprid,byte)
```

---

#### Arguments:

* **<sprid\> (Number)**: The sprite id.
* **<byte\> (Number)**: The new flag value [0-255].

---

### 2. Set a bit in the flag:

---

**Note**: The bits are currently numbered from left to right, sorry for this, will fix in the next release.

---

#### Syntax:
```lua
fset(sprid,bn,value)
```

---

#### Arguments:

* **<sprid\> (Number)**: The sprite id.
* **<bn\> (Number)**: The bit number [1-8].
* **<value\> (Boolean)**: True to set as 1, False to set as 0.