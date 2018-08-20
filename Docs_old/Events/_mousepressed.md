This function is called everytime a mouse button is pressed.

**Important Note:** Besure to call [Controls("mouse")](../DiskOS API/Controls.md) in the first line of the game !

---

#### Syntax:
```lua
function _mousepressed(x,y,button)
  --Do something here
end
```

---

#### Arguments:

* **x (Number)**: x position of cursor.
* **y (Number)**: y position of cursor.
* **button  (Number)**: pressed button, check [MouseButtons Enum](../Enums/MouseButtons.md).