Draws a triangle on the screen.

---

#### Syntax:
```lua
triangle(x1,y1, x2,y2, x3,y3, l, c)
```

---

#### Arguments:

* **<x1\> (Number)**: The first x coordinate of triangle vector.
* **<y1\> (Number)**: The first y coordinate of triangle vector.
* **<x2\> (Number)**: The second x coordinate of triangle vector.
* **<y2\> (Number)**: The second y coordinate of triangle vector.
* **<x3\> (Number)**: The third x coordinate of triangle vector.
* **<y3\> (Number)**: The third y coordinate of triangle vector.
* **[l] (Boolean)**: (false/nil) The triangle will be filled, (true) The triangle will have only lines (outline).
* **[c] (Number)**: The color of triangle (0-15), defaults to the active color.

---

### Note:

The arguments can be passed in a table:
```lua
triangle( {x1,y1, x2,y2, x3,y3, l, c} )
```

---

##### See also:

* [color()](color.md)
* [lines()](line.md)
* [polygon()](polygon.md)