Draws an ellipse on the screen.

---

#### Syntax:
```lua
ellipse(x,y,rx,ry,l,c)
```

---

#### Arguments:

* **<x\> (Number)**: The x coord of ellipse center.
* **<y\> (Number)**: The y coord of ellipse center.
* **<rx\> (Number)**: The radius of the ellipse along the x-axis (half the ellipse's width).
* **<ry\> (Number)**: The radius of the ellipse along the y-axis (half the ellipse's height).
* **[l] (Number)**: (false/nil) The ellipse will be filled, (true) The ellipse will have only lines (outline).
* **[r] (Number)**: The color of the ellipse (0-15), defaults to the active color.

---

### Note:

The arguments can be passed in a table:
```lua
ellipse( {x,y, rx,ry ,l, c} )
```