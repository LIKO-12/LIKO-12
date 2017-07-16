Draws a circle on the screen.

---

#### Syntax:
```lua
circle(x,y, r, l, c)
```

---

#### Arguments:

* **<x\> (Number)**: The x coord of circle center.
* **<y\> (Number)**: The y coord of circle center.
* **<r\> (Number)**: The radius of circle.
* **[l] (Boolean)**: (false/nil) The circle will be filled, (true) The circle will have only lines (outline).
* **[c] (Number)**: The color of the circle (0-15), defaults to the active color.

---

### Note:

The arguments can be passed in a table:
```lua
circle( {x,y, r, l, c} )
```