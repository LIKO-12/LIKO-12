# BIOS.PeripheralFunctions
---

Returns the list of available peripheral functions, and their type (Direct,Yield).

---

?> It's good to know if a method/function is a yield or direct one:
- **Direct Methods** are called directly, _fast_.
- **Yielding Methods** requires a coroutine yield, _slow_.

---

* **Available since:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0
* **Last updated in:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0

---

```lua
local functions = BIOS.PeripheralFunctions(mountName)
```

---
### Arguments
---

* **mountName (string):** The peripheral mount name.


---
### Returns
---

* **functions (table):** The peripheral functions list.


---

The peripheral functions list is a table where the keys and values are:
- **Keys**: The function/method name.
- **Values**: The function/method type (`"Direct"` or `"Yield"`).