Draws a circle on the screen.

---

#### Syntax:
```lua
circle(x,y, r, l, c, seg)
```

---

#### Arguments:

* **<x\> (Number)**: The x coord of circle center.
* **<y\> (Number)**: The y coord of circle center.
* **<r\> (Number)**: The radius of circle.
* **[l] (Boolean)**: (false/nil) The circle will be filled, (true) The circle will have only lines (outline).
* **[c] (Number)**: The color of the circle (0-15), defaults to the active color.
* **[seg] (Number)**: The number of the segments used when drawing the circle.

---

### Note:

The arguments can be passed in a table:
```lua
circle( {x,y, r, l, c} )
```

##### See also:

* [color()](color.md)

---

##### Changelog:

- **V0.6.0_PRE_04**: Added the `seg` argument.