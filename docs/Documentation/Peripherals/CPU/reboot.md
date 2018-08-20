# CPU.reboot
---

Reboot LIKO-12.

---

* **Available since:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _CPU:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Soft Reboot:
---

Soft reboots LIKO-12 by doing an internal trick to reload the BIOS and bootup again, will leave some garbage that will be cleaned automatically by the Lua garbage collector.

---

```lua
local  = CPU.reboot()
```


---
#### Arguments
---



---
#### Returns
---


---

# 2. Hard Reboot:
---

Hard reboots LIKO-12 by reinitializing the LÖVE engine, will clear the whole Lua state, and re-create the window.

---

```lua
local  = CPU.reboot("true")
```


---
#### Arguments
---

* **`"true"` (boolean)**


---
#### Returns
---


---