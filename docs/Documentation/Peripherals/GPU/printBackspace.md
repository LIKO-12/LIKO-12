# GPU.printBackspace
---

Deletes the last printed character via the 3rd and 4th variants of `print()`, and it updates the cursor position.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Delete the last character:
---

```lua
GPU.printBackspace(c)
```


---
#### Arguments
---

* **c (number):** The background color to fill the character with (**-1**,**15**), **-1** means no background, defaults to the current print cursor background color.

---

# 2. Delete the last character without doing a carriage return if needed:
---

```lua
GPU.printBackspace(c, "true")
```


---
#### Arguments
---

* **c (number):** The background color to fill the character with (**-1**,**15**), **-1** means no background, defaults to the current print cursor background color.
* **`"true"` (boolean)**

---