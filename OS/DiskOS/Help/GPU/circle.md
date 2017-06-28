Draws a circle on the screen.

---

#### Syntax:
```lua
circle(x,y, r, l, c)
```

---

#### Arguments:

* **<x\> (Number)**: The top-left x position of circle.
* **<y\> (Number)**: The top-left y position of circle.
* **<r\> (Number)**: The radius of circle.
* **[l] (Boolean)**: (false/nil) The circle will be filled, (true) The circle will have only lines (outline).
* **[c] (Number)**: The color of the circle (0-15), defaults to the active color.

---

### Note:

The arguments can be passed in a table:
```lua
circle( {x,y, r, l, c} )
```