This function is called everytime a mouse button is released.

**Important Note:** Besure to call [controls("mouse")](./DiskOSAPI/controls.md) in the first line of the game !

---

#### Syntax:
```lua
function _mousereleased(x,y,button)
  --Do something here
end
```

---

#### Arguments:

* **x (Number)**: x position of cursor.
* **y (Number)**: y position of cursor.
* **button  (Number)**: pressed button, check [MouseButtons Enum](../Enums/MouseButtons.md).