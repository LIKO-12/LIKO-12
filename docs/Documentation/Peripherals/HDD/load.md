# HDD.load
---

Loads the contents of a Lua script as a function.

---

* **Available since:** _HDD:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _HDD:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local chunk, ok = HDD.load(file)
```

---
### Arguments
---

* **file (string):** File to load.


---
### Returns
---

* **chunk (function, nil):** Loaded file function, nil when fails to load.
* **ok (string, nil):** The error message when failed to load.

