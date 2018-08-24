# BIOS.Peripherals
---

Returns a list of mounted peripherals and their types.

---

* **Available since:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0
* **Last updated in:** _BIOS:_ v1.15.2, _LIKO-12_: v0.7.0

---

```lua
local peripherals = BIOS.Peripherals()
```

---
### Returns
---

* **peripherals (table):** The peripherals list.


---

The peripherals list is a table where the keys and values are:
- **Keys**: The mount name.
- **Values**: The peripheral type.