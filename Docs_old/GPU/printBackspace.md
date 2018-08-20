Deletes the last printed character via the 3rd and 4th variants of [print()](print.md), and it updates the cursor position.

---

## Usage:

---

### 1. Delete the last character:

---

#### Syntax:
```lua
printBackspace(c)
```

---

#### Arguments:

* **[c] (Number)**: The background color to fill the character with (**-1**,**15**), **-1** means no background, defaults to the current print cursor background color.

---

### 2. Delete the last character without doing a carriage return if needed:

---

#### Syntax:
```lua
printBackspace(c,true)
```

---

#### Arguments:

* **[c] (Number)**: The background color to fill the character with (**-1**,**15**), **-1** means no background, defaults to the current print cursor background color.

---

##### See also:

* [color()](color.md)
* [print()](print.md)
* [printCursor()](printCursor.md)
* [wrapText()](wrapText.md)