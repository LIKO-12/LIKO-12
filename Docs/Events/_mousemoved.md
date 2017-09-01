This function is called everytime the mouse moves.

**Important Note:** Besure to call [Controls("mouse")](../DiskOS API/Controls.md) in the first line of the game !

---

#### Syntax:
```lua
function _mousemoved(x,y,dx,dy)
  --Do something here
end
```

---

#### Arguments:

* **x (Number)**: x position of cursor.
* **y (Number)**: y position of cursor.
* **dx (Number)**: The amount moved along the x-axis since the last time, it's a float.
* **dy (Number)**: The amount moved along the y-axis since the last time, it's a float.
