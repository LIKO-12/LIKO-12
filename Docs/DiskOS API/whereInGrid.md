Checks in what cell x and y lands on.

---
### Syntax:
```lua
cellX, cellY = whereInGrid(x,y,rectGrid)
```

---
### Arguments:
* **x (Integer)**: X position to check
* **y (Integer)**: Y position to check
* **rectGrid (List)**: Contains in order: Grid X, Grid Y (top left corner of grid), Grid height, Number of cells in width, Number of cells in height
---
### Returns:
If position is not in grid:
* **ok (Boolean)**: Always false
If position is in grid:
* **cellX (Integer)**: Cell X
* **cellY (Integer)**: Cell Y