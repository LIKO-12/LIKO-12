Changes the print cursor position used by [print()](print.md) in the grid variant.

**Note**: The positions are on a characters grid, the size of the grid can be requested from [termSize()](termSize.md)

---

## Usage:

---

### 1. Set cursor position:

---

#### Syntax:
```lua
printCursor(x,y,bgcolor)
```

---

#### Arguments:

* **[x] (Number)**: The X coord of the cursor in characters, defaults to the current Y coord.
* **[y] (Number)**: The Y corrd of the cursor in characters, defaults to the current Y coord.
* **[bgcolor] (Number)**: The background color used when printing (**-1**,**15**), **-1** means no background, defaults to the current background color.

---

### 2. Get cursor position:

---

#### Syntax:
```lua
x,y, bgcolor = printCursor()
```

---

#### Returns:

* **x (Number)**: The current X coord of the cursor in characters.
* **y (Number)**: The current Y corrd of the cursor in characters.
* **bgcolor (Number)**: The current background color.

---

##### See also:

* [color()](color.md)
* [print()](print.md)
* [printBackspace()](printBackspace.md)
* [wrapText()](wrapText.md)