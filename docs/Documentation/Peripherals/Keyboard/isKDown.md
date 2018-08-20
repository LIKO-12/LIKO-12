# Keyboard.isKDown
---

Checks whether a certain key is down.

Check [Enums/KeyConstants](/Documentation/Enums/KeyConstants.md).

---

* **Available since:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0

---

```lua
local down = Keyboard.isKDown(key, ...)
```

---
### Arguments
---

* **key (string):**  A key to check.
* **... (string):** Additional keys to check.


---
### Returns
---

* **down (boolean):** True if any supplied key is down, false if not.

