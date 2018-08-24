# BIOS.HandledAPIS
---

Returns the handled peripherals APIS, that can be used directly.

---

?> The HandledAPIS table is passed to the operating system's `boot.lua` as an argument:
```lua
--In C:/boot.lua
local HandledAPIS = ...
```

---

* **Available since:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0
* **Last updated in:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0

---

```lua
local HandledAPIS = BIOS.HandledAPIS()
```

---
### Returns
---

* **HandledAPIS (table):** The peripherals handled APIS.


---

The peripherals handled APIS is a table where the keys and values are:
- **Keys**: The mount name.
- **Values**: The peripheral methods (functions).