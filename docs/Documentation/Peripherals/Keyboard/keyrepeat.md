# Keyboard.keyrepeat
---

Enables or disables key repeat. It is disabled by default.

The interval between repeats depends on the user's system settings.

**Note:** It's better to do `if isrepeat then return true end` than calling this function.

---

* **Available since:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0
* **Last updated in:** _Keyboard:_ v1.0.0, _LIKO-12_: v0.6.0

---

**Usages:**

---

# 1. Disable/Enable key repeat:
---

```lua
Keyboard.keyrepeat(state)
```


---
#### Arguments
---

* **state (boolean):** Whether repeat keypress events should be enabled when a key is held down.

---

# 2. Get the current key repeat state:
---

```lua
local state = Keyboard.keyrepeat()
```


---
#### Returns
---

* **state (boolean):** Whether repeat keypress events should be enabled when a key is held down.

---