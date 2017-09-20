Reads a sprite flag.

---

## Usage:

---

### 1. Read the whole flag byte:

---

#### Syntax:
```lua
byte = fget(sprid)
```

---

#### Arguments:

* **<sprid\> (Number)**: The sprite id.

---

#### Returns:

* **byte (Number)**: The flag value [0-255].

---

### 2. Read a bit from the flag:

---

**Note**: The bits are currently numbered from left to right, sorry for this, will fix in the next release.

---

#### Syntax:
```lua
b = fget(sprid,bn)
```

---

#### Arguments:

* **<sprid\> (Number)**: The sprite id.
* **<bn\> (Number)**: The bit number [1-8].

---

#### Returns:

* **b (Boolean)**: True if the bit is 1, False if it's 0.