Draws a rectangle on the screen.

---

#### Syntax:
```lua
rect(x, y, w, h, l, c)
```

---

#### Arguments:

* **<x\> (Number)**: The top-left x position of the rectangle.
* **<y\> (Number)**: The top-left y position of the rectangle.
* **<w\> (Number)**: The width of rectangle.
* **<h\> (Number)**: The height of rectangle.
* **[l] (Boolean)**: (false/nil) The rectangle will be filled, (true) The rectangle will have only lines (border).
* **[c] (Number)**: The color of the rectangle (0-15), defaults to the active color.

---

### Note:

The arguments can be passed in a table:
```lua
rect( {x, y, w, h, l, c} )
```

---

##### See also:

* [color()](color.md)
* [polygon()](polygon.md)