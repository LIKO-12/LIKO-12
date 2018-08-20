Makes a specific color transparent or not, By default the color 0 is transparent.

**NOTE**: This only affects images.

---

## Usage:

---

### 1. Make a specific color transparent or not:

---

#### Syntax:
```lua
palt(c,t)
```

---

#### Arguments:

* **<c\> (Number)**: The color id (0-15).
* **<t\> (Boolean/nil)**: (true) The color will be transparent, (false/nil) The color will be opaque.

---

### 2. Reset the colors to it's default:

---

#### Syntax:
```lua
palt()
```

---

##### See also:

* [pal()](pal.md)
* [pushPalette()](pushPalette.md)
* [popPalette()](popPalette.md)