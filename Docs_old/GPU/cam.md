Transforms the drawing operations

* **Note:** The transforming operations sums up, to reset check the fifth variant of this function.

---

## Usage:

---

### 1. Traslate drawing positions:

---

Shifts all drawing operations.

---

#### Syntax:
```lua
cam("translate",x,y)
```

---

#### Arguments:

* **<x\> (Number)**: The translation relative to the x-axis.
* **<y\> (Number)**: The translation relative to the y-axis.

---

### 2. Scale drawing operations:

---

Scales all the drawing operations.

---

#### Syntax:
```lua
cam("scale",sx,sy)
```

---

#### Arguments:

* **<sx\> (Number)**: The scaling in the direction of the x-axis.
* **<sy\> (Number)**: The scaling in the direction of the y-axis.

---

### 3. Rotate drawing operations:

---

#### Syntax:
```lua
cam("rotate",a)
```

---

#### Arguments:

* **<a\> (Number)**: The amount to rotate the coordinate system in radians.

---

### 4. Shear drawing operations:

---

#### Syntax:
```lua
cam("shear",x,y)
```

---

#### Arguments:

* **<x\> (Number)**: The shear factor on the x-axis.
* **<y\> (Number)**: The shear factor on the y-axis.

---

### 5. Reset all the tranformations:

---

Resets all the tranformations done back to their original state.

---

#### Syntax:
```lua
cam()
```

---

##### See also:

* [pushMatrix()](pushMatrix.md)
* [popMatrix()](popMatrix.md)