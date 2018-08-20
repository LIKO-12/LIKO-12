Prints text to the screen, uses the current active color (check [color()](color.md) ).

---

## Usage:

---

### 1. Print at a specific position on the screen with wrapping mode:

---

#### Syntax:
```lua
print(text,x,y,limit,align,r,sx,sy,ox,oy,kx,ky)
```

---

#### Arguments:

* **<text\> (String)**: The text to draw.
* **<x\> (Number)**: The X coord to draw at.
* **<y\> (Number)**: The Y coord to draw at.
* **<limit\> (Number)**: Wrap the line after this many horizontal pixels.
* **[align] (String) ("left")**: The alignment.
* **[r] (Number)**: Rotation (radians).
* **[sx] (Number)**: Scale factor (x-axis).
* **[sy] (Number)**: Scale factor (y-axis).
* **[ox] (Number)**: Origin offset (x-axis).
* **[oy] (Number)**: Origin offset (y-axis).
* **[kx] (Number)**: Shear factor (x-axis).
* **[ky] (Number)**: Shear factor (y-axis).

---

### 2. Print at a specific position on the screen without wrapping:

---

#### Syntax:
```lua
print(text,x,y,false,false,r,sx,sy,ox,oy,kx,ky)
```

---

#### Arguments:

* **<text\> (String)**: The text to draw.
* **<x\> (Number)**: The X coord to draw at.
* **<y\> (Number)**: The Y coord to draw at.
* **[r] (Number)**: Rotation (radians).
* **[sx] (Number)**: Scale factor (x-axis).
* **[sy] (Number)**: Scale factor (y-axis).
* **[ox] (Number)**: Origin offset (x-axis).
* **[oy] (Number)**: Origin offset (y-axis).
* **[kx] (Number)**: Shear factor (x-axis).
* **[ky] (Number)**: Shear factor (y-axis).

---

### 3. Print in terminal grid way:

---

#### Syntax:
```lua
print(text)
```

---

#### Arguments:

* **<text\> (String)**: The text to draw.

---

### 4. Print in terminal grid without auto newline:

---

#### Syntax:
```lua
print(text,false)
```

---

#### Arguments:

* **<text\> (String)**: The text to draw.

---

### 5. Print in terminal grid directly without wrapping nor updating the cursor pos:

---

#### Syntax:
```lua
print(text,false,true)
```

---

#### Arguments:

* **<text\> (String)**: The text to draw.

---

##### See also:

* [color()](color.md)
* [printCursor()](printCursor.md)
* [printBackspace()](printBackspace.md)
* [wrapText()](wrapText.md)