# GPU.cam
---

Transforms the drawing operations.

---

?> The transforming operations sums up, to reset check the fifth usage of this function.

---

* **Available since:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _GPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Translate drawing positions:
---

Shifts all drawing operations.

---

```lua
GPU.cam("translate", x, y)
```


---
#### Arguments
---

* **`"translate"` (string)**
* **x (number):** The translation relative to the x-axis.
* **y (number):** The translation relative to the y-axis.

---

# 2. Scale drawing operations:
---

Scales all the drawing operations.

---

```lua
GPU.cam("scale", sx, sy)
```


---
#### Arguments
---

* **`"scale"` (string)**
* **sx (number):** The scaling in the direction of the x-axis.
* **sy (number):** The scaling in the direction of the y-axis.

---

# 3. Rotate drawing operations:
---

```lua
GPU.cam("rotate", a)
```


---
#### Arguments
---

* **`"rotate"` (string)**
* **a (number):** The amount to rotate the coordinate system in radians.

---

# 4. Shear drawing operations:
---

```lua
GPU.cam("shear", x, y)
```


---
#### Arguments
---

* **`"shear"` (string)**
* **x (number):** The shear factor on the x-axis.
* **y (number):** The shear factor on the y-axis.

---

# 5. Reset all the tranformations:
---

Resets all the tranformations done back to their original state.

---

```lua
GPU.cam()
```

---